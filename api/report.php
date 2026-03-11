<?php
// api/report.php
ini_set('display_errors', '0');
ini_set('log_errors', '1');
ini_set('error_log', __DIR__ . '/api_error.log');
error_reporting(E_ALL);

set_exception_handler(function ($e) {
    http_response_code(500);
    header('Content-Type: application/json; charset=UTF-8');
    echo json_encode([
        "error" => "Server error",
        "details" => $e->getMessage(),
    ]);
    error_log((string) $e);
    exit;
});

set_error_handler(function ($severity, $message, $file, $line) {
    throw new ErrorException($message, 0, $severity, $file, $line);
});

header('Content-Type: application/json; charset=UTF-8');

$origin = $_SERVER['HTTP_ORIGIN'] ?? '';
$allowed = [
    'https://italents.ma',
    'https://www.italents.ma',
];

// allow localhost:anyport for Flutter web dev
$isLocalhost = preg_match('#^http://localhost:\d+$#', $origin) || preg_match('#^http://127\.0\.0\.1:\d+$#', $origin);

if ($isLocalhost || in_array($origin, $allowed, true)) {
    header("Access-Control-Allow-Origin: $origin");
    header("Vary: Origin");
}

header('Access-Control-Allow-Headers: Content-Type, Authorization');
header('Access-Control-Allow-Methods: POST, OPTIONS');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    echo json_encode(["ok" => true]);
    exit;
}

require_once __DIR__ . '/config.php';

$auth = $_SERVER['HTTP_AUTHORIZATION'] ?? ($_SERVER['Authorization'] ?? '');
$payload = null;
if ($auth && preg_match('/Bearer\\s+(.*)$/i', $auth, $matches)) {
    $token = $matches[1];
    $payload = verify_jwt($token);
}

$method = $_SERVER['REQUEST_METHOD'];
$pdo = get_pdo();

function table_exists_report(PDO $pdo, string $tableName): bool
{
    try {
        $stmt = $pdo->prepare("
            SELECT 1
            FROM information_schema.TABLES
            WHERE TABLE_SCHEMA = DATABASE()
              AND TABLE_NAME = :table
            LIMIT 1
        ");
        $stmt->execute([':table' => $tableName]);
        return (bool) $stmt->fetchColumn();
    } catch (Throwable $e) {
        return false;
    }
}

if ($method !== 'POST') {
    json_response(['error' => 'Method not allowed'], 405);
}

if ($payload === null || !isset($payload['sub'])) {
    json_response(['error' => 'Token manquant ou invalide'], 401);
}

if (!table_exists_report($pdo, 'reports')) {
    json_response(['error' => 'Table reports introuvable'], 500);
}

$body = json_decode(file_get_contents('php://input'), true) ?? [];
$targetType = $body['target_type'] ?? '';
$targetId = isset($body['target_id']) ? (int) $body['target_id'] : 0;
$reason = $body['reason'] ?? '';
$details = trim((string) ($body['details'] ?? ''));

$allowedReasons = ['spam', 'scam', 'abuse', 'illegal', 'other'];
if ($targetType !== 'listing') {
    json_response(['error' => 'target_type invalide'], 400);
}
if ($targetId <= 0) {
    json_response(['error' => 'target_id requis'], 400);
}
if (!in_array($reason, $allowedReasons, true)) {
    json_response(['error' => 'reason invalide'], 400);
}

// Vérifier que la cible existe
$stmt = $pdo->prepare("SELECT id FROM listings WHERE id = :id LIMIT 1");
$stmt->execute([':id' => $targetId]);
$exists = $stmt->fetchColumn();
if (!$exists) {
    json_response(['error' => 'Annonce introuvable'], 404);
}

$stmt = $pdo->prepare("
    INSERT INTO reports (
        reporter_user_id,
        target_type,
        target_id,
        reason,
        details,
        status,
        created_at
    ) VALUES (
        :reporter_user_id,
        'listing',
        :target_id,
        :reason,
        :details,
        'open',
        NOW()
    )
");

$stmt->execute([
    ':reporter_user_id' => (int) $payload['sub'],
    ':target_id' => $targetId,
    ':reason' => $reason,
    ':details' => $details,
]);

json_response([
    'success' => true,
    'message' => 'Signalement envoyé',
]);
