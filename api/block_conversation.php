<?php

header('Content-Type: application/json; charset=UTF-8');
$origin = $_SERVER['HTTP_ORIGIN'] ?? '*';
header("Access-Control-Allow-Origin: $origin");
header('Vary: Origin');
header('Access-Control-Allow-Headers: Content-Type, Authorization');
header('Access-Control-Allow-Methods: POST, OPTIONS');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    echo json_encode(['ok' => true]);
    exit;
}

require_once __DIR__ . '/config.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    json_response(['success' => false, 'message' => 'Méthode non autorisée'], 405);
}

$body = json_decode(file_get_contents('php://input'), true) ?? [];
$conversationId = isset($body['conversation_id']) ? (int)$body['conversation_id'] : 0;
$userId = isset($body['user_id']) ? (int)$body['user_id'] : 0;
$block = !empty($body['block']); // 1 pour bloquer, 0 pour débloquer

if ($conversationId <= 0 || $userId <= 0) {
    json_response(['success' => false, 'message' => 'conversation_id et user_id requis'], 400);
}

try {
    $pdo = get_pdo();

    // Vérifier participant
    $stmt = $pdo->prepare('SELECT 1 FROM conversation_participants WHERE conversation_id = :cid AND user_id = :uid LIMIT 1');
    $stmt->execute([':cid' => $conversationId, ':uid' => $userId]);
    if (!$stmt->fetchColumn()) {
        json_response(['success' => false, 'message' => 'Accès refusé à cette conversation'], 403);
    }

    $pdo->exec("CREATE TABLE IF NOT EXISTS conversation_blocks (
        id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
        conversation_id BIGINT NOT NULL,
        blocker_user_id BIGINT NOT NULL,
        blocked_user_id BIGINT NOT NULL,
        created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
        UNIQUE KEY uniq_block (conversation_id, blocker_user_id, blocked_user_id)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;");

    // trouver l'autre participant
    $otherStmt = $pdo->prepare('SELECT user_id FROM conversation_participants WHERE conversation_id = :cid AND user_id <> :uid LIMIT 1');
    $otherStmt->execute([':cid' => $conversationId, ':uid' => $userId]);
    $otherUserId = (int)($otherStmt->fetchColumn() ?: 0);

    if ($otherUserId <= 0) {
        json_response(['success' => false, 'message' => 'Aucun autre participant trouvé'], 404);
    }

    if ($block) {
        $ins = $pdo->prepare('INSERT IGNORE INTO conversation_blocks (conversation_id, blocker_user_id, blocked_user_id) VALUES (:cid, :blocker, :blocked)');
        $ins->execute([':cid' => $conversationId, ':blocker' => $userId, ':blocked' => $otherUserId]);
        json_response(['success' => true, 'blocked' => true, 'message' => 'Utilisateur bloqué']);
    } else {
        // Débloquer : seul le bloqueur d'origine peut lever le blocage
        $del = $pdo->prepare('DELETE FROM conversation_blocks WHERE conversation_id = :cid AND blocker_user_id = :blocker');
        $del->execute([':cid' => $conversationId, ':blocker' => $userId]);
        if ($del->rowCount() === 0) {
            json_response(['success' => false, 'message' => 'Seul le bloqueur peut débloquer'], 403);
        }
        json_response(['success' => true, 'blocked' => false, 'message' => 'Blocage retiré']);
    }
} catch (Exception $e) {
    json_response(['success' => false, 'message' => $e->getMessage()], 500);
}
