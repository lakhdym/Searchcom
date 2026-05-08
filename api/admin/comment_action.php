<?php
// Admin actions for comments (listing_comments): hide / show / delete
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
    $commentId = isset($body['comment_id']) ? (int)$body['comment_id'] : 0;
    if (!$action || $commentId <= 0) respond(false, 'Action ou comment_id manquant', [], 400);

    $pdo = get_pdo();

    switch ($action) {
        case 'hide':
            $pdo->prepare("UPDATE listing_comments SET status='hidden' WHERE id=:id")->execute([':id'=>$commentId]);
            respond(true, 'Commentaire archivé', ['status'=>'hidden']);
            break;
        case 'show':
            $pdo->prepare("UPDATE listing_comments SET status='visible' WHERE id=:id")->execute([':id'=>$commentId]);
            respond(true, 'Commentaire réactivé', ['status'=>'visible']);
            break;
        case 'delete':
            $pdo->prepare("DELETE FROM listing_comments WHERE id=:id")->execute([':id'=>$commentId]);
            respond(true, 'Commentaire supprimé', ['status'=>'deleted']);
            break;
        default:
            respond(false, 'Action inconnue', [], 400);
    }
} catch (Throwable $e) {
    error_log('[admin/comment_action] '.$e->getMessage());
    respond(false, 'Erreur serveur', ['error'=>$e->getMessage()], 500);
}
