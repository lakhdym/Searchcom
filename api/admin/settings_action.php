<?php
// Save admin settings to simple key-value table
header('Content-Type: application/json; charset=UTF-8');
$origin = $_SERVER['HTTP_ORIGIN'] ?? '*';
header("Access-Control-Allow-Origin: $origin");
header('Vary: Origin');
header('Access-Control-Allow-Headers: Content-Type, Authorization');
header('Access-Control-Allow-Methods: POST, OPTIONS');
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(200); echo json_encode(['ok'=>true]); exit; }

require_once __DIR__ . '/../config.php';

function respond($ok, $message, $extra = [], $status = 200) {
    http_response_code($status);
    echo json_encode(array_merge(['success'=>$ok, 'message'=>$message], $extra), JSON_UNESCAPED_UNICODE);
    exit;
}

try {
    if ($_SERVER['REQUEST_METHOD'] !== 'POST') respond(false, 'Méthode non autorisée', [], 405);
    $body = json_decode(file_get_contents('php://input'), true);
    if (!is_array($body)) respond(false, 'Payload JSON invalide', [], 400);

    $pdo = get_pdo();
    $pdo->exec("CREATE TABLE IF NOT EXISTS settings (
        `key` varchar(100) NOT NULL,
        `value` text NOT NULL,
        `updated_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        PRIMARY KEY (`key`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;");

    $stmt = $pdo->prepare("INSERT INTO settings (`key`,`value`) VALUES (:k,:v)
                            ON DUPLICATE KEY UPDATE `value` = VALUES(`value`), updated_at = CURRENT_TIMESTAMP");
    foreach ($body as $k => $v) {
        $stmt->execute([':k'=>$k, ':v'=> is_scalar($v) ? (string)$v : json_encode($v)]);
    }

    respond(true, 'Paramètres enregistrés');
} catch (Throwable $e) {
    error_log('[admin/settings_action] '.$e->getMessage());
    respond(false, 'Erreur serveur', ['error'=>$e->getMessage()], 500);
}
