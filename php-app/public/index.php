<?php
declare(strict_types=1);

use Smollan\App\Application;

require dirname(__DIR__) . '/vendor/autoload.php';
require dirname(__DIR__) . '/app/bootstrap.php';

$app = new Application();
$app->run();
