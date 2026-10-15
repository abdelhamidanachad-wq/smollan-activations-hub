<?php
declare(strict_types=1);

namespace Smollan\Support;

use PDO;

final class Audit {
    public static function record(PDO $pdo, string $action, string $entity, ?string $id, string $summary, array $meta=[]): void {
        $stmt=$pdo->prepare('insert into public.smollan_audit_events(actor_id,action,entity_type,entity_id,summary,metadata) values (:actor,:action,:entity,cast(:id as uuid),:summary,cast(:meta as jsonb))');
        $stmt->execute(['actor'=>Auth::user()['id'] ?? null,'action'=>$action,'entity'=>$entity,'id'=>$id,'summary'=>$summary,'meta'=>json_encode($meta, JSON_THROW_ON_ERROR)]);
    }
}
