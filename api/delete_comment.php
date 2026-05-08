<?php

header('Content-Type: application/json; charset=UTF-8');
$origin = $_SERVER['HTTP_ORIGIN'] ?? '*';
header("Access-Control-Allow-Origin: $origin");
header('Vary: Origin');
header('Access-Control-Allow-Headers: Content-Type, Authorization');
header('Access-Control-Allow-Methods: DELETE, POST, OPTIONS');

if (($_SERVER['REQUEST_METHOD'] ?? 'POST') === 'OPTIONS') {
    http_response_code(200);
    echo json_encode(['ok' => true], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
    exit;
}

require_once __DIR__ . '/comment_utils.php';

$method = $_SERVER['REQUEST_METHOD'] ?? 'POST';
if (!in_array($method, ['DELETE', 'POST'], true)) {
    json_response(['success' => false, 'message' => 'Method not allowed'], 405);
}

try {
    $pdo = get_pdo();
    ensure_comment_schema($pdo);

    $userId = require_authenticated_user_id();
    $body = json_decode(file_get_contents('php://input'), true) ?? [];
    $commentId = isset($body['comment_id']) ? (int) $body['comment_id'] : 0;

    if ($commentId <= 0) {
        json_response(['success' => false, 'message' => 'comment_id requis'], 400);
    }

    $existing = fetch_comment_row($pdo, $commentId);
    if ($existing === null) {
        json_response(['success' => false, 'message' => 'Commentaire introuvable'], 404);
    }

    if ((int) ($existing['user_id'] ?? 0) !== $userId) {
        json_response(['success' => false, 'message' => 'Acces non autorise'], 403);
    }

    if (!empty($existing['deleted_at'])) {
        $comment = fetch_comment_payload($pdo, $commentId);
        json_response([
            'success' => true,
            'message' => 'Commentaire supprime',
            'comment' => $comment,
        ]);
    }

    $stmt = $pdo->prepare("
        UPDATE listing_comments
        SET status = 'hidden',
            updated_at = NOW(),
            deleted_at = NOW(),
            deleted_by_user_id = :deleted_by_user_id
        WHERE id = :comment_id
          AND user_id = :user_id
          AND deleted_at IS NULL
        LIMIT 1
    ");
    $stmt->execute([
        ':deleted_by_user_id' => $userId,
        ':comment_id' => $commentId,
        ':user_id' => $userId,
    ]);

    $comment = fetch_comment_payload($pdo, $commentId);
    json_response([
        'success' => true,
        'message' => 'Commentaire supprime',
        'comment' => $comment,
    ]);
} catch (Throwable $e) {
    json_response(['success' => false, 'message' => 'Erreur serveur'], 500);
}
