<?php
declare(strict_types=1);

namespace Smollan\Repositories;

use PDO;
use RuntimeException;

final class OperationsRepository {
    public function __construct(private PDO $pdo) {}
    public function count(string $table, string $where = 'true', array $params=[]): int {
        $allowed=['smollan_clients','smollan_projects','smollan_tasks','smollan_promoters','smollan_stores','smollan_supervisors','smollan_assignments','smollan_attendance','smollan_resource_requests','smollan_gifts','smollan_plv_materials','smollan_quotations','smollan_expenses','smollan_assets','smollan_whatsapp_groups','smollan_pec_records','smollan_uniform_skus'];
        if (!in_array($table,$allowed,true)) throw new RuntimeException('Unsupported table');
        $stmt=$this->pdo->prepare("select count(*) from public.{$table} where {$where}");
        $stmt->execute($params);
        return (int)$stmt->fetchColumn();
    }
    public function rows(string $table, string $order='created_at', int $limit=100, string $search=''): array {
        $schemas=[
          'clients'=>['table'=>'smollan_clients','columns'=>'id::text,name,code,contact_name,contact_email,contact_phone,created_at','search'=>'name'],
          'projects'=>['table'=>'smollan_projects','columns'=>'p.id::text,p.code,p.name,p.status::text,p.service_type::text,p.start_date,p.end_date,p.budget,p.currency,c.name as client_name','search'=>'p.name'],
          'promoters'=>['table'=>'smollan_promoters','columns'=>'id::text,full_name,phone,email,city,status,contract_type,uniform_size','search'=>'full_name'],
          'stores'=>['table'=>'smollan_stores','columns'=>'id::text,source_code,name,city,banner,format,address,operating_hours,status','search'=>'name'],
          'supervisors'=>['table'=>'smollan_supervisors','columns'=>'id::text,full_name,phone,email,city,zone,status','search'=>'full_name'],
          'attendance'=>['table'=>'smollan_attendance','columns'=>'a.id::text,a.attendance_date,a.status,a.validation_status,a.check_in,a.check_out,p.full_name as promoter_name,pr.name as project_name,s.name as store_name','search'=>'p.full_name'],
          'tasks'=>['table'=>'smollan_tasks','columns'=>'t.id::text,t.title,t.status::text,t.priority,t.due_at,t.description,p.name as project_name','search'=>'t.title'],
          'resources'=>['table'=>'smollan_resource_requests','columns'=>'r.id::text,r.request_type,r.status,r.created_at,r.decision_reason,p.full_name as promoter_name,pr.name as project_name,s.name as store_name','search'=>'p.full_name'],
          'goodies'=>['table'=>'smollan_gifts','columns'=>'g.id::text,g.name,g.category,g.total_quantity,g.unit_value,g.status,pr.name as project_name','search'=>'g.name'],
          'posm'=>['table'=>'smollan_plv_materials','columns'=>'m.id::text,m.name,m.material_type,m.total_quantity,m.unit_cost,m.production_status,m.production_deadline,pr.name as project_name','search'=>'m.name'],
          'uniforms'=>['table'=>'smollan_uniform_skus','columns'=>'id::text,sku,name,size,color,quantity_on_hand,reorder_level,unit_cost,status','search'=>'name'],
          'assets'=>['table'=>'smollan_assets','columns'=>'a.id::text,a.asset_code,a.name,a.asset_type,a.serial_number,a.status,a.assigned_to,a.purchase_cost,pr.name as project_name','search'=>'a.name'],
          'finance'=>['table'=>'smollan_expenses','columns'=>'e.id::text,e.category,e.amount,e.spend_type,e.expense_date,e.approval_status,e.payment_status,pr.name as project_name','search'=>'e.category'],
          'quotations'=>['table'=>'smollan_quotations','columns'=>'q.id::text,q.quotation_number,q.quotation_date,q.status,q.total_amount,q.currency,c.name as client_name,pr.name as project_name','search'=>'q.quotation_number'],
          'hr'=>['table'=>'smollan_pec_records','columns'=>'x.id::text,x.pec_status,x.start_date,x.end_date,p.full_name as promoter_name,pr.name as project_name','search'=>'p.full_name'],
          'whatsapp'=>['table'=>'smollan_whatsapp_groups','columns'=>'w.id::text,w.name,w.group_type,w.client_name,w.city,w.group_url,w.owner_name,w.status,pr.name as project_name','search'=>'w.name'],
        ];
        if (!isset($schemas[$table])) throw new RuntimeException('Unsupported module');
        $s=$schemas[$table]; $tableName=$s['table']; $cols=$s['columns'];
        $from="public.{$tableName}";
        $joins='';
        if($table==='projects') $joins=' left join public.smollan_clients c on c.id=p.client_id';
        if($table==='attendance') $joins=' a join public.smollan_promoters p on p.id=a.promoter_id join public.smollan_projects pr on pr.id=a.project_id join public.smollan_stores s on s.id=a.store_id';
        if($table==='tasks') $joins=' t left join public.smollan_projects p on p.id=t.project_id';
        if($table==='resources') $joins=' r join public.smollan_promoters p on p.id=r.promoter_id join public.smollan_projects pr on pr.id=r.project_id left join public.smollan_stores s on s.id=r.store_id';
        if($table==='goodies') $joins=' g join public.smollan_projects pr on pr.id=g.project_id';
        if($table==='posm') $joins=' m join public.smollan_projects pr on pr.id=m.project_id';
        if($table==='assets') $joins=' a left join public.smollan_projects pr on pr.id=a.project_id';
        if($table==='finance') $joins=' e join public.smollan_projects pr on pr.id=e.project_id';
        if($table==='quotations') $joins=' q left join public.smollan_clients c on c.id=q.client_id join public.smollan_projects pr on pr.id=q.project_id';
        if($table==='hr') $joins=' x join public.smollan_promoters p on p.id=x.promoter_id left join public.smollan_projects pr on pr.id=x.project_id';
        if($table==='whatsapp') $joins=' w left join public.smollan_projects pr on pr.id=w.project_id';
        $alias=match($table){'projects'=>'p','attendance'=>'a','tasks'=>'t','resources'=>'r','goodies'=>'g','posm'=>'m','assets'=>'a','finance'=>'e','quotations'=>'q','hr'=>'x','whatsapp'=>'w',default=>''};
        $searchColumn=$s['search'];
        $where=$search!=='' ? " where {$searchColumn} ilike :search" : '';
        $orderColumn = match($table) {
          'projects'=>'p.created_at','attendance'=>'a.attendance_date','tasks'=>'t.due_at','resources'=>'r.created_at',
          'goodies'=>'g.name','posm'=>'m.name','assets'=>'a.name','finance'=>'e.expense_date','quotations'=>'q.quotation_date','hr'=>'x.end_date','whatsapp'=>'w.name',
          default=>'created_at'
        };
        $sql="select {$cols} from {$from}{$joins}{$where} order by {$orderColumn} desc nulls last limit :lim";
        $stmt=$this->pdo->prepare($sql);
        if($search!=='') $stmt->bindValue(':search','%'.$search.'%');
        $stmt->bindValue(':lim',max(1,min(500,$limit)),PDO::PARAM_INT);
        $stmt->execute();
        return $stmt->fetchAll();
    }
    public function projectsForSelect(): array {
        return $this->pdo->query("select id::text as id,name from public.smollan_projects order by name")->fetchAll();
    }
    public function clientsForSelect(): array {
        return $this->pdo->query("select id::text as id,name from public.smollan_clients order by name")->fetchAll();
    }
}
