<?php
// api/test_connection.php
// Petit script de test pour vérifier la connexion à la base de données.

require_once __DIR__ . '/config.php';

try {
    // Essayer d'obtenir une connexion PDO et exécuter un petit SELECT 1
    $pdo = get_pdo();
    $stmt = $pdo->query('SELECT 1');
    $stmt->fetch();

    // Succès
    json_response([
        'success' => true,
        'message' => 'Connexion à la base de données réussie.',
        'database' => DB_NAME,
        'host' => DB_HOST,
    ]);
} catch (Throwable $e) {
    // Échec
    json_response([
        'success' => false,
        'message' => 'Erreur de connexion à la base de données.',
        'error' => $e->getMessage(),
    ], 500);
}

