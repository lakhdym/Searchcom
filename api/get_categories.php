<?php
// api/get_categories.php
header('Content-Type: application/json; charset=UTF-8');

require_once __DIR__ . '/config.php';

$origin = $_SERVER['HTTP_ORIGIN'] ?? '';
if ($origin) {
    header("Access-Control-Allow-Origin: $origin");
    header("Vary: Origin");
}
header('Access-Control-Allow-Headers: Content-Type, Authorization');
header('Access-Control-Allow-Methods: GET, OPTIONS');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    echo json_encode(['ok' => true]);
    exit;
}

$pdo = get_pdo();

$stmt = $pdo->query("SHOW COLUMNS FROM categories");
$cols = $stmt ? $stmt->fetchAll(PDO::FETCH_COLUMN, 0) : [];
$idCol = in_array('id', $cols, true) ? 'id' : $cols[0];
$nameCol = in_array('name_fr', $cols, true)
    ? 'name_fr'
    : (in_array('name', $cols, true) ? 'name' : $cols[1] ?? 'name_fr');

$stmt = $pdo->query("SELECT `$idCol` AS id, slug, name_fr, name_en, name_ar FROM categories ORDER BY `$nameCol`");
$rows = $stmt ? $stmt->fetchAll(PDO::FETCH_ASSOC) : [];

json_response([
    'success' => true,
    'categories' => $rows,
]);
