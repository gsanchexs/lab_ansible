<?php
$password = readline('insira sua senha pra converter em hash bcrypt: ');
$hash = password_hash($password, PASSWORD_BCRYPT);
echo "1|" . $hash . PHP_EOL;
?>