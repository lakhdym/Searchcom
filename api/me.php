<?php

header('Content-Type: application/json; charset=UTF-8');

require_once __DIR__ . '/config.php';

// Simple placeholder endpoint (UI only for now).
// In the future, plug JWT/session verification here.
json_response([
    'success' => true,
    'message' => 'Endpoint en préparation',
]);
