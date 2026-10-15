<?php
declare(strict_types=1);

namespace Smollan\Services;

use PDO;
use Smollan\Support\Auth;
use Smollan\Support\Audit;
use RuntimeException;
use Throwable;

final class WorkflowService {
    public function __construct(private PDO $pdo) {}
    public function createQuotation(array $data): string {
        if(!Auth::can('platform_admin','leadership','finance','activation_coordinator')) throw new RuntimeException('Role is not permitted to create quotations.');
        $projectId=(string)($data['project_id']??''); $lines=$data['lines']??[];
        if($projectId===''||!is_array($lines)||count($lines)===0) throw new RuntimeException('Choose a project and add at least one line item.');
        $this->pdo->beginTransaction();
        try {
            $number='Q-'.date('Ymd').'-'.strtoupper(bin2hex(random_bytes(3)));
            $header=$this->pdo->prepare("insert into public.smollan_quotations(project_id,client_id,quotation_number,quotation_date,status,total_amount,currency,notes,created_by) select p.id,p.client_id,:number,current_date,'Draft',0,'MAD',:notes,cast(:actor as uuid) from public.smollan_projects p where p.id=cast(:project as uuid) returning id::text");
            $header->execute(['number'=>$number,'notes'=>trim((string)($data['notes']??'')),'actor'=>Auth::user()['id'],'project'=>$projectId]);
            $id=$header->fetchColumn();
            if(!$id) throw new RuntimeException('Project not found.');
            $line=$this->pdo->prepare('insert into public.smollan_quotation_lines(quotation_id,description,quantity,unit_price) values (cast(:id as uuid),:description,:quantity,:price)');
            foreach($lines as $item) {
                $desc=trim((string)($item['description']??'')); $qty=(float)($item['quantity']??0); $price=(float)($item['unit_price']??-1);
                if($desc===''||$qty<=0||$price<0) throw new RuntimeException('Each line needs a description, positive quantity and non-negative unit price.');
                $line->execute(['id'=>$id,'description'=>$desc,'quantity'=>$qty,'price'=>$price]);
            }
            $sum=$this->pdo->prepare('update public.smollan_quotations set total_amount=(select coalesce(sum(line_total),0) from public.smollan_quotation_lines where quotation_id=cast(:id as uuid)) where id=cast(:id as uuid)');
            $sum->execute(['id'=>$id]);
            Audit::record($this->pdo,'created','quotation',$id,'Created quotation '.$number,['line_count'=>count($lines)]);
            $this->pdo->commit(); return $id;
        } catch(Throwable $e) { if($this->pdo->inTransaction()) $this->pdo->rollBack(); throw $e; }
    }
    public function createExpense(array $d): string {
        if(!Auth::can('platform_admin','leadership','finance','activation_coordinator')) throw new RuntimeException('Role is not permitted to submit expenses.');
        $amount=filter_var($d['amount']??null,FILTER_VALIDATE_FLOAT);
        if(!$amount || $amount<0 || empty($d['project_id']) || empty($d['category'])) throw new RuntimeException('Project, category and non-negative amount are required.');
        $stmt=$this->pdo->prepare("insert into public.smollan_expenses(project_id,category,amount,spend_type,justification,expense_date,receipt_ref,approval_status,payment_status,notes,submitted_by) values (cast(:project as uuid),:category,:amount,:type,:justification,:date,:receipt,'Pending','Unpaid',:notes,cast(:actor as uuid)) returning id::text");
        $stmt->execute(['project'=>$d['project_id'],'category'=>trim($d['category']),'amount'=>$amount,'type'=>in_array($d['spend_type']??'',['Planned','Additional'],true)?$d['spend_type']:'Planned','justification'=>trim($d['justification']??''),'date'=>$d['expense_date']?:date('Y-m-d'),'receipt'=>trim($d['receipt_ref']??'')?:null,'notes'=>trim($d['notes']??''),'actor'=>Auth::user()['id']]);
        $id=(string)$stmt->fetchColumn(); Audit::record($this->pdo,'submitted','expense',$id,'Submitted expense for review',['amount'=>$amount]); return $id;
    }
    public function decideExpense(string $id,string $decision,?string $notes): void {
        if(!Auth::can('platform_admin','leadership','finance')) throw new RuntimeException('Finance approval role required.');
        if(!in_array($decision,['Approved','Rejected'],true)) throw new RuntimeException('Invalid decision.');
        $stmt=$this->pdo->prepare('update public.smollan_expenses set approval_status=:status,notes=concat_ws(E\'\\n\',nullif(notes,\'\'),:notes),reviewed_by=cast(:actor as uuid),updated_at=now() where id=cast(:id as uuid) and approval_status=\'Pending\' returning id::text');
        $stmt->execute(['status'=>$decision,'notes'=>$notes,'actor'=>Auth::user()['id'],'id'=>$id]);
        if(!$stmt->fetchColumn()) throw new RuntimeException('Expense not found or has already been decided.');
        Audit::record($this->pdo,'decision','expense',$id,'Expense '.$decision,['reason'=>$notes]);
    }
    public function decideResource(string $id,string $decision,?string $reason): void {
        if(!Auth::can('platform_admin','leadership','activation_coordinator','field_operations','hr_coordinator')) throw new RuntimeException('Request approval role required.');
        if(!in_array($decision,['Approved','Rejected'],true)) throw new RuntimeException('Invalid decision.');
        $stmt=$this->pdo->prepare("update public.smollan_resource_requests set status=:status,decision_reason=:reason,decided_by=cast(:actor as uuid),decided_at=now(),updated_at=now() where id=cast(:id as uuid) and status='Pending' returning id::text");
        $stmt->execute(['status'=>$decision,'reason'=>$reason,'actor'=>Auth::user()['id'],'id'=>$id]);
        if(!$stmt->fetchColumn()) throw new RuntimeException('Request not found or has already been decided.');
        Audit::record($this->pdo,'decision','resource_request',$id,'Resource request '.$decision,['reason'=>$reason]);
    }
}
