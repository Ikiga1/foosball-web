<?php
date_default_timezone_set('Europe/Amsterdam');
# Folder containing the database. If the STATE_DIRECTORY environment variable is set, use this one.
$STATE_DIR = getenv("STATE_DIRECTORY") ?: "../db";
$pdo = new PDO("sqlite:" . $STATE_DIR . "/foos.db", NULL, NULL, array(PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION));
?>
