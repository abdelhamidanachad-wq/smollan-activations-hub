<?php
declare(strict_types=1);

namespace Smollan\Services;

use PDO;
use Smollan\Support\Auth;
use Smollan\Support\Audit;
use RuntimeException;

final class AttendanceService {
    public function __construct(private PDO $pdo) {}

    public function checkIn(string $assignmentId, ?string $photoRef, ?float $lat=null, ?float $lng=null): string {
        if(!Auth::active()) throw new RuntimeException('Active SMOLLAN membership is required.');
        $membership=Auth::membership(); $user=Auth::user();
        $assignment=$this->pdo->prepare("select a.id::text,a.promoter_id::text,a.project_id::text,a.store_id::text,p.user_id::text from public.smollan_assignments a join public.smollan_promoters p on p.id=a.promoter_id where a.id=cast(:id as uuid) and a.status='Active' and a.start_date<=current_date and (a.end_date is null or a.end_date>=current_date)");
        $assignment->execute(['id'=>$assignmentId]);
        $a=$assignment->fetch(PDO::FETCH_ASSOC);
        if(!$a) throw new RuntimeException('No active assignment was found for check-in.');

        $selfPromoter=($a['user_id']??null)===$user['id'] && ($membership['role']??'')==='promoter';
        $manager=in_array($membership['role']??'', ['platform_admin','leadership','activation_coordinator','field_operations','supervisor'],true);
        if(!$selfPromoter&&!$manager) throw new RuntimeException('You are not allowed to check in this assignment.');

        $stmt=$this->pdo->prepare("insert into public.smollan_attendance as existing(assignment_id,promoter_id,project_id,store_id,attendance_date,status,check_in,source,photo_ref,validation_status,notes) values (cast(:assignment as uuid),cast(:promoter as uuid),cast(:project as uuid),cast(:store as uuid),current_date,'Present',now(),:source,:photo,'Pending',:notes) on conflict (assignment_id,attendance_date) do update set check_in=coalesce(existing.check_in,excluded.check_in),source=excluded.source,photo_ref=coalesce(excluded.photo_ref,existing.photo_ref),updated_at=now() returning id::text");
        $stmt->execute([
            'assignment'=>$a['id'],'promoter'=>$a['promoter_id'],'project'=>$a['project_id'],'store'=>$a['store_id'],
            'source'=>$selfPromoter?'Portal':'Supervisor App','photo'=>$photoRef,
            'notes'=>$lat!==null&&$lng!==null?'Check-in coordinates captured with consent; coordinates are not persisted by this endpoint.':null
        ]);
        $id=(string)$stmt->fetchColumn();
        Audit::record($this->pdo,'check_in','attendance',$id,'Attendance check-in saved',['assignment_id'=>$assignmentId]);
        return $id;
    }

    public function checkOut(string $attendanceId): void {
        if(!Auth::active()) throw new RuntimeException('Active membership required.');
        $stmt=$this->pdo->prepare("update public.smollan_attendance a set check_out=now(),updated_at=now() where a.id=cast(:id as uuid) and a.check_in is not null and a.check_out is null and (exists(select 1 from public.smollan_assignments x join public.smollan_promoters p on p.id=x.promoter_id where x.id=a.assignment_id and p.user_id=cast(:user as uuid)) or cast(:role as text) in ('platform_admin','leadership','activation_coordinator','field_operations','supervisor')) returning a.id::text");
        $stmt->execute(['id'=>$attendanceId,'user'=>Auth::user()['id'],'role'=>Auth::membership()['role']]);
        $id=$stmt->fetchColumn();
        if(!$id) throw new RuntimeException('Attendance not found, already closed, or not in your scope.');
        Audit::record($this->pdo,'check_out','attendance',(string)$id,'Attendance check-out saved');
    }
}
