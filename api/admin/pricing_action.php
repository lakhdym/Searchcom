<?php
// Admin endpoint to save pricing settings
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

    $publish = isset($body['publish_price']) ? (float)$body['publish_price'] : null;
    $boost   = isset($body['boost_price']) ? (float)$body['boost_price'] : null;
    $currency = isset($body['currency']) ? trim($body['currency']) : 'MAD';
    if ($currency === '') $currency = 'MAD';
    if ($publish === null || $boost === null) respond(false, 'Champs requis manquants', [], 400);

    $pdo = get_pdo();
    $stmt = $pdo->prepare("INSERT INTO app_settings (id, currency, publish_price, boost_price, updated_at) VALUES (1, :c, :p, :b, NOW())
                           ON DUPLICATE KEY UPDATE currency = VALUES(currency), publish_price = VALUES(publish_price), boost_price = VALUES(boost_price), updated_at = NOW()");
    $stmt->execute([
        ':c' => mb_substr($currency, 0, 10),
        ':p' => $publish,
        ':b' => $boost,
    ]);

    respond(true, 'Tarifs mis à jour', ['currency'=>$currency]);
} catch (Throwable $e) {
    error_log('[admin/pricing_action] '.$e->getMessage());
    respond(false, 'Erreur serveur', ['error'=>$e->getMessage()], 500);
}
