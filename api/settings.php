<?php

ob_start();
header('Content-Type: application/json; charset=UTF-8');

$origin = $_SERVER['HTTP_ORIGIN'] ?? '*';
header("Access-Control-Allow-Origin: $origin");
header('Vary: Origin');
header('Access-Control-Allow-Headers: Content-Type, Authorization');
header('Access-Control-Allow-Methods: GET, OPTIONS');

if (($_SERVER['REQUEST_METHOD'] ?? 'GET') === 'OPTIONS') {
    http_response_code(200);
    echo json_encode(['success' => true], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
    exit;
}

$respond = function (bool $success, int $status = 200, ?string $message = null, array $extra = []) {
    if (ob_get_length()) {
        @ob_clean();
    }

    http_response_code($status);
    $payload = array_merge(['success' => $success], $message !== null ? ['message' => $message] : [], $extra);
    echo json_encode(
        $payload,
        JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES | JSON_INVALID_UTF8_SUBSTITUTE
    );
    exit;
};

require_once __DIR__ . '/config.php';

if (($_SERVER['REQUEST_METHOD'] ?? 'GET') !== 'GET') {
    $respond(false, 405, 'Method not allowed');
}

$lang = strtolower(trim((string)($_GET['lang'] ?? 'fr')));
if (!in_array($lang, ['fr', 'en', 'ar'], true)) {
    $lang = 'fr';
}

try {
    $pdo = get_pdo();

    $conditions = load_conditions_from_key_value_settings($pdo, $lang);

    $respond(true, 200, null, [
        'data' => [
            'conditions' => $conditions,
        ],
    ]);
} catch (Throwable $e) {
    $respond(false, 500, 'Erreur serveur');
}

function load_conditions_from_key_value_settings(PDO $pdo, string $lang): ?string
{
    $keys = [
        'page_condition_utilisations_' . $lang,
        'page_condition_utilisations_fr',
        'page_condition_utilisations_en',
        'page_condition_utilisations_ar',
    ];

    $seen = [];

    foreach ($keys as $key) {
        if (isset($seen[$key])) {
            continue;
        }
        $seen[$key] = true;

        $stmt = $pdo->prepare("SELECT `value` FROM `settings` WHERE `key` = :key LIMIT 1");
        $stmt->execute([':key' => $key]);
        $value = $stmt->fetchColumn();

        $normalized = normalize_condition_text($value);
        if ($normalized !== null) {
            return $normalized;
        }
    }

    return null;
}

function normalize_condition_text($value): ?string
{
    if ($value === null) {
        return null;
    }

    $text = trim((string)$value);
    if ($text === '') {
        return null;
    }

    $text = preg_replace('#<br\s*/?>#i', "\n", $text) ?? $text;
    $text = preg_replace('#</p\s*>#i', "\n\n", $text) ?? $text;
    $text = preg_replace('#</li\s*>#i', "\n", $text) ?? $text;
    $text = strip_tags($text);
    $text = html_entity_decode($text, ENT_QUOTES | ENT_HTML5, 'UTF-8');
    $text = str_replace(["\r\n", "\r"], "\n", $text);
    $text = preg_replace("/\n{3,}/", "\n\n", $text) ?? $text;

    $normalized = trim($text);
    return $normalized === '' ? null : $normalized;
}
