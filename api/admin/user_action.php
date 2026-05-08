<?php
// Simple admin user actions endpoint: view / ban / unban / delete (soft-ban) users.
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
    $body = json_decode(file_get_contents('php://input'), true);
    if (!is_array($body)) respond(false, 'Payload JSON invalide', [], 400);
    $action = $body['action'] ?? null;
    $userId = isset($body['user_id']) ? (int)$body['user_id'] : 0;
    if (!$action || $userId <= 0) respond(false, 'Action ou user_id manquant', [], 400);

    $pdo = get_pdo();

    switch ($action) {
        case 'view':
            $stmt = $pdo->prepare("SELECT id, full_name, email, phone, preferred_lang, is_banned, created_at FROM users WHERE id = :id LIMIT 1");
            $stmt->execute([':id'=>$userId]);
            $user = $stmt->fetch();
            if (!$user) respond(false, 'Utilisateur introuvable', [], 404);
            respond(true, 'OK', ['user'=>$user]);
            break;

        case 'ban':
            $pdo->prepare("UPDATE users SET is_banned = 1 WHERE id = :id")->execute([':id'=>$userId]);
            respond(true, 'Utilisateur banni', ['status'=>'banned']);
            break;

        case 'unban':
            $pdo->prepare("UPDATE users SET is_banned = 0 WHERE id = :id")->execute([':id'=>$userId]);
            respond(true, 'Utilisateur débanni', ['status'=>'active']);
            break;

        case 'delete':
            // Soft delete for safety: mark banned and anonymize email/phone
            $pdo->prepare("UPDATE users SET is_banned = 1, email = CONCAT('deleted+', id, '@example.local'), phone = NULL, full_name = CONCAT(full_name, ' (deleted)') WHERE id = :id")->execute([':id'=>$userId]);
            respond(true, 'Utilisateur supprimé (soft)', ['status'=>'deleted']);
            break;

        default:
            respond(false, 'Action inconnue', [], 400);
    }
} catch (Throwable $e) {
    error_log('[admin/user_action] '.$e->getMessage());
    respond(false, 'Erreur serveur', ['error'=>$e->getMessage()], 500);
}
