<?php
declare(strict_types=1);

namespace Smollan\Repositories;

use PDO;
use RuntimeException;

final class OperationsRepository {
    public function __construct(private PDO $pdo) {}

    public function count(string $table, string $where='true', array $params=[]): int {
        $allowed=[
            'smollan_clients','smollan_projects','smollan_tasks','smollan_promoters',
            'smollan_stores','smollan_supervisors','smollan_assignments','smollan_attendance',
            'smollan_resource_requests','smollan_gifts','smollan_plv_materials','smollan_quotations',
            'smollan_expenses','smollan_assets','smollan_whatsapp_groups','smollan_pec_records',
            'smollan_uniform_skus','smollan_uniform_transactions','smollan_gift_dispatches',
            'smollan_plv_store_records'
        ];
        if(!in_array($table,$allowed,true)) throw new RuntimeException('Unsupported table');
        $stmt=$this->pdo->prepare("select count(*) from public.{$table} where {$where}");
        $stmt->execute($params);
        return (int)$stmt->fetchColumn();
    }

    public function rows(string $module, string $order='created_at', int $limit=100, string $search=''): array {
        $schemas=[
          'clients'=>['from'=>'public.smollan_clients c','columns'=>'c.id::text as id,c.name,c.code,c.contact_name,c.contact_email,c.contact_phone,c.created_at','search'=>'c.name','order'=>'c.created_at'],
          'projects'=>['from'=>'public.smollan_projects p left join public.smollan_clients c on c.id=p.client_id','columns'=>'p.id::text as id,p.code,p.name,p.status::text as status,p.service_type::text as service_type,p.start_date,p.end_date,p.budget,p.currency,c.name as client_name','search'=>'p.name','order'=>'p.created_at'],
          'promoters'=>['from'=>'public.smollan_promoters p','columns'=>'p.id::text as id,p.full_name,p.phone,p.email,p.city,p.status,p.contract_type,p.uniform_size','search'=>'p.full_name','order'=>'p.full_name'],
          'stores'=>['from'=>'public.smollan_stores s','columns'=>'s.id::text as id,s.source_code,s.name,s.city,s.banner,s.format,s.address,s.operating_hours,s.status','search'=>'s.name','order'=>'s.name'],
          'supervisors'=>['from'=>'public.smollan_supervisors su','columns'=>'su.id::text as id,su.full_name,su.phone,su.email,su.city,su.zone,su.status','search'=>'su.full_name','order'=>'su.full_name'],
          'attendance'=>['from'=>'public.smollan_attendance a join public.smollan_promoters p on p.id=a.promoter_id join public.smollan_projects pr on pr.id=a.project_id join public.smollan_stores s on s.id=a.store_id','columns'=>'a.id::text as id,a.attendance_date,a.status,a.validation_status,a.check_in,a.check_out,p.full_name as promoter_name,pr.name as project_name,s.name as store_name','search'=>'p.full_name','order'=>'a.attendance_date'],
          'tasks'=>['from'=>'public.smollan_tasks t left join public.smollan_projects p on p.id=t.project_id','columns'=>'t.id::text as id,t.title,t.status::text as status,t.priority,t.due_at,t.description,p.name as project_name','search'=>'t.title','order'=>'t.due_at'],
          'resources'=>['from'=>'public.smollan_resource_requests r join public.smollan_promoters p on p.id=r.promoter_id join public.smollan_projects pr on pr.id=r.project_id left join public.smollan_stores s on s.id=r.store_id','columns'=>'r.id::text as id,r.request_type,r.status,r.created_at,r.decision_reason,p.full_name as promoter_name,pr.name as project_name,s.name as store_name','search'=>'p.full_name','order'=>'r.created_at'],
          'goodies'=>['from'=>'public.smollan_gifts g join public.smollan_projects pr on pr.id=g.project_id','columns'=>'g.id::text as id,g.name,g.category,g.total_quantity,g.unit_value,g.status,pr.name as project_name','search'=>'g.name','order'=>'g.name'],
          'posm'=>['from'=>'public.smollan_plv_materials m join public.smollan_projects pr on pr.id=m.project_id','columns'=>'m.id::text as id,m.name,m.material_type,m.total_quantity,m.unit_cost,m.production_status,m.production_deadline,pr.name as project_name','search'=>'m.name','order'=>'m.name'],
          'uniforms'=>['from'=>'public.smollan_uniform_skus u','columns'=>'u.id::text as id,u.sku,u.name,u.size,u.color,u.quantity_on_hand,u.reorder_level,u.unit_cost,u.status','search'=>'u.name','order'=>'u.name'],
          'assets'=>['from'=>'public.smollan_assets a left join public.smollan_projects pr on pr.id=a.project_id','columns'=>'a.id::text as id,a.asset_code,a.name,a.asset_type,a.serial_number,a.status,a.assigned_to,a.purchase_cost,pr.name as project_name','search'=>'a.name','order'=>'a.name'],
          'finance'=>['from'=>'public.smollan_expenses e join public.smollan_projects pr on pr.id=e.project_id','columns'=>'e.id::text as id,e.category,e.amount,e.spend_type,e.expense_date,e.approval_status,e.payment_status,pr.name as project_name','search'=>'e.category','order'=>'e.expense_date'],
          'quotations'=>['from'=>'public.smollan_quotations q left join public.smollan_clients c on c.id=q.client_id join public.smollan_projects pr on pr.id=q.project_id','columns'=>'q.id::text as id,q.quotation_number,q.quotation_date,q.status,q.total_amount,q.currency,c.name as client_name,pr.name as project_name','search'=>'q.quotation_number','order'=>'q.quotation_date'],
          'hr'=>['from'=>'public.smollan_pec_records x join public.smollan_promoters p on p.id=x.promoter_id left join public.smollan_projects pr on pr.id=x.project_id','columns'=>'x.id::text as id,x.pec_status,x.start_date,x.end_date,p.full_name as promoter_name,pr.name as project_name','search'=>'p.full_name','order'=>'x.end_date'],
          'whatsapp'=>['from'=>'public.smollan_whatsapp_groups w left join public.smollan_projects pr on pr.id=w.project_id','columns'=>'w.id::text as id,w.name,w.group_type,w.client_name,w.city,w.group_url,w.owner_name,w.status,pr.name as project_name','search'=>'w.name','order'=>'w.name'],
        ];
        if(!isset($schemas[$module])) throw new RuntimeException('Unsupported module');
        $s=$schemas[$module];
        $where=$search!=='' ? ' where '.$s['search'].' ilike :search' : '';
        $sql='select '.$s['columns'].' from '.$s['from'].$where.' order by '.$s['order'].' desc nulls last limit :lim';
        $stmt=$this->pdo->prepare($sql);
        if($search!=='') $stmt->bindValue(':search','%'.$search.'%');
        $stmt->bindValue(':lim',max(1,min(500,$limit)),PDO::PARAM_INT);
        $stmt->execute();
        return $stmt->fetchAll();
    }

    public function projectsForSelect(): array {
        return $this->pdo->query('select id::text as id,name from public.smollan_projects order by name')->fetchAll();
    }
    public function clientsForSelect(): array {
        return $this->pdo->query('select id::text as id,name from public.smollan_clients order by name')->fetchAll();
    }
}
