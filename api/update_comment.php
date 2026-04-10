<?php

header('Content-Type: application/json; charset=UTF-8');
$origin = $_SERVER['HTTP_ORIGIN'] ?? '*';
header("Access-Control-Allow-Origin: $origin");
header('Vary: Origin');
header('Access-Control-Allow-Headers: Content-Type, Authorization');
header('Access-Control-Allow-Methods: PUT, PATCH, POST, OPTIONS');

if (($_SERVER['REQUEST_METHOD'] ?? 'POST') === 'OPTIONS') {
    http_response_code(200);
    echo json_encode(['ok' => true], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
    exit;
}

require_once __DIR__ . '/comment_utils.php';

$method = $_SERVER['REQUEST_METHOD'] ?? 'POST';
if (!in_array($method, ['PUT', 'PATCH', 'POST'], true)) {
    json_response(['success' => false, 'message' => 'Method not allowed'], 405);
}

try {
    $pdo = get_pdo();
    ensure_comment_schema($pdo);

    $userId = require_authenticated_user_id();
    $body = json_decode(file_get_contents('php://input'), true) ?? [];
    $commentId = isset($body['comment_id']) ? (int) $body['comment_id'] : 0;
    $content = trim((string) ($body['content'] ?? ''));

    if ($commentId <= 0 || $content === '') {
        json_response(['success' => false, 'message' => 'comment_id et content requis'], 400);
    }

    $existing = fetch_comment_row($pdo, $commentId);
    if ($existing === null) {
        json_response(['success' => false, 'message' => 'Commentaire introuvable'], 404);
    }

    if ((int) ($existing['user_id'] ?? 0) !== $userId) {
        json_response(['success' => false, 'message' => 'Acces non autorise'], 403);
    }

    if (!empty($existing['deleted_at'])) {
        json_response(['success' => false, 'message' => 'Commentaire deja supprime'], 409);
    }

    $oldContent = trim((string) ($existing['content'] ?? ''));
    if ($oldContent === $content) {
        $comment = fetch_comment_payload($pdo, $commentId);
        json_response([
            'success' => true,
            'message' => 'Commentaire mis a jour',
            'comment' => $comment,
        ]);
    }

    $pdo->beginTransaction();

    $editStmt = $pdo->prepare("
        INSERT INTO comment_edits (
            comment_id,
            editor_user_id,
            old_content,
            new_content,
            created_at
        ) VALUES (
            :comment_id,
            :editor_user_id,
            :old_content,
            :new_content,
            NOW()
        )
    ");
    $editStmt->execute([
        ':comment_id' => $commentId,
        ':editor_user_id' => $userId,
        ':old_content' => $oldContent,
        ':new_content' => $content,
    ]);

    $updateStmt = $pdo->prepare("
        UPDATE listing_comments
        SET content = :content,
            updated_at = NOW()
        WHERE id = :comment_id
          AND user_id = :user_id
          AND deleted_at IS NULL
        LIMIT 1
    ");
    $updateStmt->execute([
        ':content' => $content,
        ':comment_id' => $commentId,
        ':user_id' => $userId,
    ]);

    $pdo->commit();

    $comment = fetch_comment_payload($pdo, $commentId);
    json_response([
        'success' => true,
        'message' => 'Commentaire mis a jour',
        'comment' => $comment,
    ]);
} catch (Throwable $e) {
    if (isset($pdo) && $pdo instanceof PDO && $pdo->inTransaction()) {
        $pdo->rollBack();
    }
    json_response(['success' => false, 'message' => $e->getMessage() . ' Erreur serveur'], 500);
}
