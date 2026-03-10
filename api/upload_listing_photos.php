<?php
// api/upload_listing_photos.php
ini_set('display_errors', '0');
ini_set('log_errors', '1');
ini_set('error_log', __DIR__ . '/api_error.log');
header('Content-Type: application/json; charset=UTF-8');
require_once __DIR__ . '/config.php';

$origin = $_SERVER['HTTP_ORIGIN'] ?? '';
if ($origin) {
    header("Access-Control-Allow-Origin: $origin");
    header("Vary: Origin");
}
header('Access-Control-Allow-Headers: Content-Type, Authorization');
header('Access-Control-Allow-Methods: POST, OPTIONS');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    echo json_encode(['ok' => true]);
    exit;
}
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    json_response(['success' => false, 'message' => 'Method not allowed'], 405);
}

$auth = $_SERVER['HTTP_AUTHORIZATION'] ?? ($_SERVER['Authorization'] ?? '');
if (!preg_match('/Bearer\\s+(.*)$/i', $auth, $m)) {
    json_response(['success' => false, 'message' => 'token manquant'], 401);
}
$payload = verify_jwt($m[1]);
if ($payload === null) {
    json_response(['success' => false, 'message' => 'token invalide'], 401);
}

$pdo = get_pdo();
$stmt = $pdo->prepare("
    SELECT 1 FROM information_schema.TABLES
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'listing_photos' LIMIT 1
");
$stmt->execute();
if (!$stmt->fetchColumn()) {
    json_response(['success' => false, 'message' => 'Table listing_photos introuvable'], 400);
}

$listingId = isset($_POST['listing_id']) ? (int) $_POST['listing_id'] : 0;
if ($listingId <= 0) {
    json_response(['success' => false, 'message' => 'listing_id requis'], 400);
}
if (!isset($_FILES['photos'])) {
    json_response(['success' => false, 'message' => 'Aucun fichier'], 400);
}

$uploadDir = __DIR__ . '/../uploads/annonces';
if (!is_dir($uploadDir)) mkdir($uploadDir, 0775, true);

$position = 0;
$saved = [];
foreach ($_FILES['photos']['tmp_name'] as $idx => $tmpPath) {
    if (!is_uploaded_file($tmpPath)) continue;
    $origName = $_FILES['photos']['name'][$idx] ?? 'photo';
    $ext = pathinfo($origName, PATHINFO_EXTENSION);
    $filename = uniqid('listing_', true) . ($ext ? ".$ext" : '');
    $dest = $uploadDir . '/' . $filename;
    if (!move_uploaded_file($tmpPath, $dest)) continue;

    $stmt = $pdo->prepare("
        INSERT INTO listing_photos (listing_id, url, position, created_at)
        VALUES (:lid, :url, :pos, NOW())
    ");
    $stmt->execute([
        ':lid' => $listingId,
        ':url' => $filename,
        ':pos' => $position++,
    ]);
    $saved[] = photo_url($filename);
}

json_response(['success' => true, 'photos' => $saved]);
