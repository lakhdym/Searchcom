<?php

header('Content-Type: application/json; charset=UTF-8');
$origin = $_SERVER['HTTP_ORIGIN'] ?? '*';
header("Access-Control-Allow-Origin: $origin");
header('Vary: Origin');
header('Access-Control-Allow-Headers: Content-Type, Authorization');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    echo json_encode(['ok' => true]);
    exit;
}

require_once __DIR__ . '/config.php';

$body = [];
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $body = json_decode(file_get_contents('php://input'), true) ?? [];
}

$userId = isset($_GET['user_id']) ? (int)$_GET['user_id'] : (int)($body['user_id'] ?? 0);
if ($userId <= 0) {
    json_response(['success' => false, 'message' => 'user_id requis'], 400);
}

try {
    $pdo = get_pdo();
    $stats = [
        'total' => 0,
        'published' => 0,
        'pending_payment' => 0,
        'hidden' => 0,
        'archived' => 0,
        'draft' => 0,
        'boosted' => 0,
    ];

    $stmt = $pdo->prepare("SELECT status, COUNT(*) as cnt FROM listings WHERE user_id = :uid GROUP BY status");
    $stmt->execute([':uid' => $userId]);
    foreach ($stmt->fetchAll(PDO::FETCH_ASSOC) as $row) {
        $stats['total'] += (int)$row['cnt'];
        if (isset($stats[$row['status']])) {
            $stats[$row['status']] = (int)$row['cnt'];
        }
    }

    $boostStmt = $pdo->prepare("SELECT COUNT(*) FROM listings WHERE user_id = :uid AND is_boosted = 1");
    $boostStmt->execute([':uid' => $userId]);
    $stats['boosted'] = (int)$boostStmt->fetchColumn();

    json_response(['success' => true, 'stats' => $stats]);
} catch (Throwable $e) {
    json_response(['success' => false, 'message' => 'Erreur serveur : ' . $e->getMessage()], 500);
}
