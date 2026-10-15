<?php
declare(strict_types=1);

namespace Smollan\Support;

final class Policy {
    private const MAP = [
        'overview'=>['platform_admin','leadership','activation_coordinator','field_operations','finance','procurement_production','merchandising','supervisor','read_only_client'],
        'clients'=>['platform_admin','leadership','activation_coordinator','finance','read_only_client'],
        'projects'=>['platform_admin','leadership','activation_coordinator','field_operations','procurement_production','merchandising','supervisor','read_only_client'],
        'promoters'=>['platform_admin','leadership','activation_coordinator','field_operations','supervisor','hr_coordinator'],
        'stores'=>['platform_admin','leadership','activation_coordinator','field_operations','merchandising','supervisor'],
        'supervisors'=>['platform_admin','leadership','activation_coordinator','field_operations'],
        'attendance'=>['platform_admin','leadership','activation_coordinator','field_operations','supervisor','hr_coordinator'],
        'surveys'=>['platform_admin','leadership','activation_coordinator','field_operations','supervisor'],
        'goodies'=>['platform_admin','leadership','activation_coordinator','procurement_production','merchandising','supervisor'],
        'posm'=>['platform_admin','leadership','activation_coordinator','procurement_production','merchandising','supervisor'],
        'uniforms'=>['platform_admin','leadership','activation_coordinator','hr_coordinator','field_operations'],
        'assets'=>['platform_admin','leadership','activation_coordinator','field_operations','procurement_production'],
        'hr'=>['platform_admin','leadership','hr_coordinator'],
        'resources'=>['platform_admin','leadership','activation_coordinator','field_operations','supervisor','hr_coordinator'],
        'finance'=>['platform_admin','leadership','finance'],
        'procurement'=>['platform_admin','leadership','procurement_production','finance'],
        'integrations'=>['platform_admin','leadership'],
        'imports'=>['platform_admin','leadership','activation_coordinator','finance','hr_coordinator','procurement_production'],
    ];
    public static function allows(string $module): bool {
        return Auth::active() && in_array(Auth::membership()['role'] ?? '', self::MAP[$module] ?? [], true);
    }
    public static function requireModule(string $module): void {
        if (!Auth::user()) { Http::flash('warning','Please sign in with your SMOLLAN account.'); Http::redirect('/login'); }
        if (!self::allows($module)) { http_response_code(403); echo 'Access denied'; exit; }
    }
}
