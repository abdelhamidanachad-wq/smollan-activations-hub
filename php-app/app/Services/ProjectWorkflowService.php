<?php
declare(strict_types=1);

namespace Smollan\Services;

use PDO;
use RuntimeException;
use Smollan\Support\Auth;
use Smollan\Support\Audit;

final class ProjectWorkflowService {
    public function __construct(private PDO $pdo) {}

    private function requireManager(): void {
        if (!Auth::can('platform_admin','leadership','activation_coordinator','field_manager','field_operations','supervisor','client_services')) {
            throw new RuntimeException('Your role cannot manage this project workflow.');
        }
    }

    public function createProject(array $data): string {
        if (!Auth::can('platform_admin','leadership','activation_coordinator','field_manager')) {
            throw new RuntimeException('Only project coordinators can create projects.');
        }
        $clientId = trim((string)($data['client_id'] ?? ''));
        $name = trim((string)($data['name'] ?? ''));
        $serviceType = (string)($data['service_type'] ?? 'activation');
        $allowedTypes = ['permanent_promoters','activation','production_only','in_store_animation','merchandising'];
        if ($clientId === '' || $name === '' || !in_array($serviceType, $allowedTypes, true)) {
            throw new RuntimeException('Choose a client, enter a project name, and select a valid service type.');
        }
        $start = trim((string)($data['start_date'] ?? '')) ?: null;
        $end = trim((string)($data['end_date'] ?? '')) ?: null;
        if ($start && $end && $end < $start) throw new RuntimeException('End date must be on or after start date.');
        $budgetRaw = trim((string)($data['budget'] ?? ''));
        $budget = $budgetRaw === '' ? null : filter_var($budgetRaw, FILTER_VALIDATE_FLOAT);
        if ($budget !== null && ($budget === false || $budget < 0)) throw new RuntimeException('Budget must be a non-negative number.');
        $cities = implode(',', array_values(array_unique(array_filter(array_map('trim', explode(',', (string)($data['cities'] ?? '')))))));
        $modules = array_values(array_intersect((array)($data['modules'] ?? []), ['goodies','plv','uniforms']));
        $storeIds = array_values(array_unique(array_filter((array)($data['store_ids'] ?? []), fn($x) => is_string($x) && preg_match('/^[0-9a-f-]{36}$/i', $x))));
        $this->pdo->beginTransaction();
        try {
            $id = null;
            for ($attempt=0; $attempt<3; $attempt++) {
                $code = 'SM-' . date('ym') . '-' . strtoupper(bin2hex(random_bytes(3)));
                $stmt = $this->pdo->prepare("insert into public.smollan_projects(code,client_id,name,service_type,cadence,status,start_date,end_date,cities,budget,currency,created_by,owner_id) values(:code,cast(:client as uuid),:name,cast(:service as public.project_service_type),cast(:cadence as public.project_cadence),cast(:status as public.project_status),:start,:end,string_to_array(:cities,','),:budget,'MAD',cast(:actor as uuid),cast(:actor as uuid)) returning id::text");
                try {
                    $stmt->execute(['code'=>$code,'client'=>$clientId,'name'=>$name,'service'=>$serviceType,'cadence'=>in_array(($data['cadence']??'none'),['VSD','SD','none'],true)?$data['cadence']:'none','status'=>'planning','start'=>$start,'end'=>$end,'cities'=>$cities,'budget'=>$budget,'actor'=>Auth::user()['id']]);
                    $id = (string)$stmt->fetchColumn();
                    break;
                } catch (\PDOException $e) {
                    if ($attempt===2 || !str_contains(strtolower($e->getMessage()),'unique')) throw $e;
                }
            }
            if (!$id) throw new RuntimeException('Could not allocate a project code.');
            $moduleStmt = $this->pdo->prepare("insert into public.smollan_project_modules(project_id,module_key,enabled,configured_by) values(cast(:project as uuid),:module,true,cast(:actor as uuid)) on conflict(project_id,module_key) do update set enabled=true,configured_by=excluded.configured_by,configured_at=now()");
            foreach ($modules as $module) $moduleStmt->execute(['project'=>$id,'module'=>$module,'actor'=>Auth::user()['id']]);
            foreach ($storeIds as $storeId) $this->attachStore($id,$storeId);
            Audit::record($this->pdo,'create','project',$id,'Project created',['modules'=>$modules,'store_count'=>count($storeIds)]);
            $this->pdo->commit();
            return $id;
        } catch (\Throwable $e) {
            if ($this->pdo->inTransaction()) $this->pdo->rollBack();
            throw $e;
        }
    }

    private function attachStore(string $projectId, string $storeId): void {
        $lookup = $this->pdo->prepare("select id::text from public.smollan_stores where id=cast(:id as uuid) and status='Active'");
        $lookup->execute(['id'=>$storeId]);
        if (!$lookup->fetchColumn()) throw new RuntimeException('One selected store is no longer active.');
        $sup = $this->pdo->prepare("select supervisor_id::text from public.smollan_store_supervisors where store_id=cast(:store as uuid) order by is_primary desc,created_at asc limit 1");
        $sup->execute(['store'=>$storeId]);
        $supervisorId = $sup->fetchColumn() ?: null;
        $link = $this->pdo->prepare("insert into public.smollan_project_stores(project_id,store_id,supervisor_id) values(cast(:project as uuid),cast(:store as uuid),cast(:supervisor as uuid)) on conflict(project_id,store_id) do update set supervisor_id=coalesce(public.smollan_project_stores.supervisor_id,excluded.supervisor_id)");
        $link->execute(['project'=>$projectId,'store'=>$storeId,'supervisor'=>$supervisorId]);
        if ($supervisorId) {
            $projectSup = $this->pdo->prepare("insert into public.smollan_project_supervisors(project_id,supervisor_id) values(cast(:project as uuid),cast(:supervisor as uuid)) on conflict do nothing");
            $projectSup->execute(['project'=>$projectId,'supervisor'=>$supervisorId]);
        }
    }

    public function addStore(string $projectId, string $storeId): void {
        $this->requireManager();
        $this->pdo->beginTransaction();
        try {
            $this->attachStore($projectId,$storeId);
            Audit::record($this->pdo,'link','project_store',$projectId,'Store added to project',['store_id'=>$storeId]);
            $this->pdo->commit();
        } catch (\Throwable $e) { if($this->pdo->inTransaction())$this->pdo->rollBack(); throw $e; }
    }

    public function assignPromoter(string $projectId, string $storeId, string $promoterId, string $startDate, ?string $endDate): string {
        $this->requireManager();
        if ($startDate==='' || ($endDate && $endDate<$startDate)) throw new RuntimeException('Choose a valid assignment date range.');
        $this->pdo->beginTransaction();
        try {
            $q=$this->pdo->prepare("select ps.supervisor_id::text from public.smollan_project_stores ps where ps.project_id=cast(:project as uuid) and ps.store_id=cast(:store as uuid)");
            $q->execute(['project'=>$projectId,'store'=>$storeId]);
            $supervisor=$q->fetchColumn();
            if ($supervisor===false) throw new RuntimeException('Add this store to the project before assigning a promoter.');
            $check=$this->pdo->prepare("select id::text from public.smollan_promoters where id=cast(:promoter as uuid) and status <> 'Inactive'");
            $check->execute(['promoter'=>$promoterId]);
            if (!$check->fetchColumn()) throw new RuntimeException('Promoter not found or inactive.');
            $stmt=$this->pdo->prepare("insert into public.smollan_assignments(promoter_id,project_id,store_id,supervisor_id,start_date,end_date,status,created_by) values(cast(:promoter as uuid),cast(:project as uuid),cast(:store as uuid),cast(:supervisor as uuid),:start,:end,'Active',cast(:actor as uuid)) returning id::text");
            $stmt->execute(['promoter'=>$promoterId,'project'=>$projectId,'store'=>$storeId,'supervisor'=>$supervisor ?: null,'start'=>$startDate,'end'=>$endDate,'actor'=>Auth::user()['id']]);
            $id=(string)$stmt->fetchColumn();
            $this->pdo->prepare("update public.smollan_promoters set status='Assigned',updated_at=now() where id=cast(:id as uuid)")->execute(['id'=>$promoterId]);
            Audit::record($this->pdo,'assign','promoter',$promoterId,'Promoter assigned to project/store',['project_id'=>$projectId,'store_id'=>$storeId,'assignment_id'=>$id,'supervisor_id'=>$supervisor ?: null]);
            $this->pdo->commit();
            return $id;
        } catch (\Throwable $e) { if($this->pdo->inTransaction())$this->pdo->rollBack(); throw $e; }
    }

    public function createPromoter(array $data): string {
        if (!Auth::can('platform_admin','leadership','activation_coordinator','field_manager','hr_coordinator')) throw new RuntimeException('Your role cannot create promoters.');
        $name=trim((string)($data['full_name']??''));
        if ($name==='') throw new RuntimeException('Promoter name is required.');
        $email=strtolower(trim((string)($data['email']??''))) ?: null;
        if ($email && !filter_var($email,FILTER_VALIDATE_EMAIL)) throw new RuntimeException('Enter a valid email address.');
        $stmt=$this->pdo->prepare("insert into public.smollan_promoters(full_name,phone,email,city,contract_type,status,notes) values(:name,:phone,:email,:city,:contract,'Available',:notes) returning id::text");
        $stmt->execute(['name'=>$name,'phone'=>trim((string)($data['phone']??''))?:null,'email'=>$email,'city'=>trim((string)($data['city']??''))?:null,'contract'=>in_array(($data['contract_type']??''),['Permanent','Activation','Freelance'],true)?$data['contract_type']:'Activation','notes'=>trim((string)($data['notes']??''))?:null]);
        $id=(string)$stmt->fetchColumn();
        Audit::record($this->pdo,'create','promoter',$id,'Promoter profile created',['auth_account_created'=>false]);
        return $id;
    }

    public function projectData(string $projectId): array {
        $q=$this->pdo->prepare("select p.id::text,p.code,p.name,p.status::text as status,p.service_type::text as service_type,p.start_date,p.end_date,p.cities,p.budget,p.currency,c.name as client_name from public.smollan_projects p join public.smollan_clients c on c.id=p.client_id where p.id=cast(:id as uuid)");
        $q->execute(['id'=>$projectId]); $project=$q->fetch(PDO::FETCH_ASSOC);
        if (!$project) throw new RuntimeException('Project not found.');
        $q=$this->pdo->prepare("select module_key,enabled from public.smollan_project_modules where project_id=cast(:id as uuid) order by module_key");
        $q->execute(['id'=>$projectId]); $modules=$q->fetchAll(PDO::FETCH_ASSOC);
        $q=$this->pdo->prepare("select ps.store_id::text, s.name as store_name,s.city,ps.supervisor_id::text,su.full_name as supervisor_name,ps.expected_promoters,(select count(*) from public.smollan_assignments a where a.project_id=ps.project_id and a.store_id=ps.store_id and a.status='Active') as active_promoters from public.smollan_project_stores ps join public.smollan_stores s on s.id=ps.store_id left join public.smollan_supervisors su on su.id=ps.supervisor_id where ps.project_id=cast(:id as uuid) order by s.name");
        $q->execute(['id'=>$projectId]); $stores=$q->fetchAll(PDO::FETCH_ASSOC);
        $q=$this->pdo->prepare("select a.id::text,a.promoter_id::text,p.full_name,p.phone,a.store_id::text,s.name as store_name,a.supervisor_id::text,su.full_name as supervisor_name,a.start_date,a.end_date,a.status from public.smollan_assignments a join public.smollan_promoters p on p.id=a.promoter_id join public.smollan_stores s on s.id=a.store_id left join public.smollan_supervisors su on su.id=a.supervisor_id where a.project_id=cast(:id as uuid) order by a.created_at desc limit 200");
        $q->execute(['id'=>$projectId]); $assignments=$q->fetchAll(PDO::FETCH_ASSOC);
        $q=$this->pdo->prepare("select id::text,title,summary,status,created_at from public.smollan_project_reports where project_id=cast(:id as uuid) order by created_at desc limit 50");
        $q->execute(['id'=>$projectId]); $reports=$q->fetchAll(PDO::FETCH_ASSOC);
        return ['project'=>$project,'modules'=>$modules,'stores'=>$stores,'assignments'=>$assignments,'reports'=>$reports];
    }

    public function createReport(string $projectId, string $title, string $summary): string {
        if (!Auth::can('platform_admin','leadership','activation_coordinator','field_manager','client_services')) throw new RuntimeException('Your role cannot publish client reports.');
        $title=trim($title); if (mb_strlen($title)<2) throw new RuntimeException('Report title must contain at least two characters.');
        $metrics=[];
        foreach ([
            'stores'=>["select count(*) from public.smollan_project_stores where project_id=cast(:id as uuid)",'id'],
            'active_assignments'=>["select count(*) from public.smollan_assignments where project_id=cast(:id as uuid) and status='Active'",'id'],
            'attendance_today'=>["select count(*) from public.smollan_attendance where project_id=cast(:id as uuid) and attendance_date=current_date",'id'],
            'goodies_items'=>["select count(*) from public.smollan_gifts where project_id=cast(:id as uuid)",'id'],
            'plv_items'=>["select count(*) from public.smollan_plv_materials where project_id=cast(:id as uuid)",'id']
        ] as $key=>$item) { $q=$this->pdo->prepare($item[0]); $q->execute(['id'=>$projectId]); $metrics[$key]=(int)$q->fetchColumn(); }
        $stmt=$this->pdo->prepare("insert into public.smollan_project_reports(project_id,title,summary,metrics,status,created_by) values(cast(:project as uuid),:title,:summary,cast(:metrics as jsonb),'published',cast(:actor as uuid)) returning id::text");
        $stmt->execute(['project'=>$projectId,'title'=>$title,'summary'=>trim($summary),'metrics'=>json_encode($metrics,JSON_THROW_ON_ERROR),'actor'=>Auth::user()['id']]);
        return (string)$stmt->fetchColumn();
    }

    public function createReportShare(string $reportId): string {
        if (!Auth::can('platform_admin','leadership','activation_coordinator','field_manager','client_services')) throw new RuntimeException('Your role cannot share client reports.');
        $token=rtrim(strtr(base64_encode(random_bytes(32)),'+/','-_'),'=');
        $stmt=$this->pdo->prepare("insert into public.smollan_report_share_links(report_id,token_hash,expires_at,created_by) select id,:hash,now()+interval '30 days',cast(:actor as uuid) from public.smollan_project_reports where id=cast(:id as uuid) returning id::text");
        $stmt->execute(['hash'=>hash('sha256',$token),'actor'=>Auth::user()['id'],'id'=>$reportId]);
        if (!$stmt->fetchColumn()) throw new RuntimeException('Report not found.');
        return $token;
    }

    public function publicReport(string $token): ?array {
        $q=$this->pdo->prepare("select r.title,r.summary,r.metrics::text as metrics,p.name as project_name,p.code as project_code,l.expires_at from public.smollan_report_share_links l join public.smollan_project_reports r on r.id=l.report_id join public.smollan_projects p on p.id=r.project_id where l.token_hash=:hash and l.revoked_at is null and (l.expires_at is null or l.expires_at>now()) and r.status='published'");
        $q->execute(['hash'=>hash('sha256',$token)]); $r=$q->fetch(PDO::FETCH_ASSOC);
        if (!$r) return null;
        $r['metrics']=json_decode((string)$r['metrics'],true) ?: [];
        return $r;
    }

    public function createAttendanceLink(string $assignmentId): string {
        $this->requireManager();
        $token=rtrim(strtr(base64_encode(random_bytes(32)),'+/','-_'),'=');
        $q=$this->pdo->prepare("insert into public.smollan_attendance_links(assignment_id,token_hash,expires_at,created_by) select a.id,:hash,now()+interval '14 days',cast(:actor as uuid) from public.smollan_assignments a where a.id=cast(:id as uuid) and a.status='Active' returning id::text");
        $q->execute(['hash'=>hash('sha256',$token),'actor'=>Auth::user()['id'],'id'=>$assignmentId]);
        if (!$q->fetchColumn()) throw new RuntimeException('Active assignment not found.');
        return $token;
    }

    public function resolveAttendanceLink(string $token): ?array {
        $q=$this->pdo->prepare("select l.id::text as link_id,a.id::text as assignment_id,p.full_name,pr.name as project_name,s.name as store_name,l.expires_at from public.smollan_attendance_links l join public.smollan_assignments a on a.id=l.assignment_id join public.smollan_promoters p on p.id=a.promoter_id join public.smollan_projects pr on pr.id=a.project_id join public.smollan_stores s on s.id=a.store_id where l.token_hash=:hash and l.revoked_at is null and l.expires_at>now() and a.status='Active' and a.start_date<=current_date and (a.end_date is null or a.end_date>=current_date)");
        $q->execute(['hash'=>hash('sha256',$token)]); return $q->fetch(PDO::FETCH_ASSOC) ?: null;
    }

    public function checkInWithLink(string $token, ?string $photoRef=null): void {
        $link=$this->resolveAttendanceLink($token);
        if (!$link) throw new RuntimeException('This check-in link has expired or is no longer active.');
        $q=$this->pdo->prepare("insert into public.smollan_attendance(assignment_id,promoter_id,project_id,store_id,attendance_date,status,check_in,source,photo_ref,validation_status) select a.id,a.promoter_id,a.project_id,a.store_id,current_date,'Present',now(),'Check-in Link',:photo,'Pending' from public.smollan_assignments a where a.id=cast(:assignment as uuid) on conflict(assignment_id,attendance_date) do update set check_in=coalesce(public.smollan_attendance.check_in,excluded.check_in),source='Check-in Link',photo_ref=coalesce(excluded.photo_ref,public.smollan_attendance.photo_ref),updated_at=now()");
        $q->execute(['photo'=>$photoRef,'assignment'=>$link['assignment_id']]);
        $this->pdo->prepare("update public.smollan_attendance_links set revoked_at=now() where id=cast(:id as uuid)")->execute(['id'=>$link['link_id']]);
    }

    public function createProjectItem(string $module, array $data): string {
        $this->requireManager();
        $projectId=trim((string)($data['project_id']??''));
        $name=trim((string)($data['name']??''));
        if ($projectId==='' || $name==='') throw new RuntimeException('Choose a project and enter an item name.');
        if (!in_array($module,['goodies','plv','uniforms'],true)) throw new RuntimeException('Unsupported project item type.');
        $feature=$this->pdo->prepare("select enabled from public.smollan_project_modules where project_id=cast(:project as uuid) and module_key=:module");
        $feature->execute(['project'=>$projectId,'module'=>$module]);
        if (!in_array($feature->fetchColumn(),[true,'t','true',1,'1'],true)) throw new RuntimeException('Enable this module in the project configuration before adding items.');
        if ($module==='goodies') {
            $q=$this->pdo->prepare("insert into public.smollan_gifts(project_id,name,category,source,total_quantity,unit_value,status,description) values(cast(:project as uuid),:name,:category,:source,:qty,:cost,:status,:description) returning id::text");
            $q->execute(['project'=>$projectId,'name'=>$name,'category'=>trim((string)($data['category']??''))?:null,'source'=>trim((string)($data['source']??''))?:null,'qty'=>max(0,(int)($data['quantity']??0)),'cost'=>max(0,(float)($data['unit_cost']??0)),'status'=>trim((string)($data['status']??'Planning'))?:'Planning','description'=>trim((string)($data['description']??''))?:null]);
        } elseif ($module==='plv') {
            $q=$this->pdo->prepare("insert into public.smollan_plv_materials(project_id,name,material_type,production_source,total_quantity,unit_cost,production_status,production_deadline,status,description) values(cast(:project as uuid),:name,:type,:source,:qty,:cost,:production_status,:deadline,:status,:description) returning id::text");
            $q->execute(['project'=>$projectId,'name'=>$name,'type'=>trim((string)($data['material_type']??''))?:'Other','source'=>trim((string)($data['source']??''))?:null,'qty'=>max(0,(int)($data['quantity']??0)),'cost'=>max(0,(float)($data['unit_cost']??0)),'production_status'=>trim((string)($data['status']??'Planning'))?:'Planning','deadline'=>trim((string)($data['deadline']??''))?:null,'status'=>trim((string)($data['status']??'Planning'))?:'Planning','description'=>trim((string)($data['description']??''))?:null]);
        } else {
            $sku=trim((string)($data['sku']??'')); if($sku==='') throw new RuntimeException('A unique SKU is required for uniform items.');
            $q=$this->pdo->prepare("insert into public.smollan_uniform_skus(project_id,sku,name,size,color,quantity_on_hand,reorder_level,unit_cost,status,notes,created_by) values(cast(:project as uuid),:sku,:name,:size,:color,:qty,:reorder,:cost,'active',:notes,cast(:actor as uuid)) returning id::text");
            $q->execute(['project'=>$projectId,'sku'=>$sku,'name'=>$name,'size'=>trim((string)($data['size']??''))?:null,'color'=>trim((string)($data['color']??''))?:null,'qty'=>max(0,(int)($data['quantity']??0)),'reorder'=>max(0,(int)($data['reorder_level']??0)),'cost'=>max(0,(float)($data['unit_cost']??0)),'notes'=>trim((string)($data['description']??''))?:null,'actor'=>Auth::user()['id']]);
        }
        $id=(string)$q->fetchColumn();
        Audit::record($this->pdo,'create','project_item',$id,'Project item created',['project_id'=>$projectId,'module'=>$module]);
        return $id;
    }
}
