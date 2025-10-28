<?php
// Gera 10 arquivos XML com conteúdo fictício
for ($i = 1; $i <= 10; $i++) {
    $filename = "arquivo_$i.xml";
    $conteudo = <<<XML
<?xml version="1.0" encoding="UTF-8"?>
<documento>
    <id>$i</id>
    <nome>Lorem Ipsum $i</nome>
    <descricao>Lorem ipsum dolor sit amet, consectetur adipiscing elit. Maecenas tortor nibh, fermentum ac odio vitae, mollis vehicula arcu. Pellentesque ultricies eget nisl quis pharetra. Donec sed viverra sem. Phasellus interdum sit amet tellus non hendrerit. Ut ullamcorper massa mauris. Pellentesque molestie venenatis nibh, eget consectetur neque sagittis sit amet. Morbi volutpat est tellus, nec malesuada nibh varius non. Nam id cursus tellus. Interdum et malesuada fames ac ante ipsum primis in faucibus. Vivamus eget porttitor sem. Suspendisse mattis nisl eget tortor eleifend maximus. Donec quis mollis nibh. Morbi at sapien a turpis aliquet semper. In vitae velit ut metus tristique convallis et ut enim.
        Vestibulum tempor, dolor vitae lobortis pharetra, dolor mauris sollicitudin elit, quis venenatis justo sem non urna. Sed et turpis sed ipsum elementum facilisis. Nunc nulla nulla, tincidunt eget egestas at, semper sed diam. Sed porta nec dui ac cursus. Quisque ut massa quis libero dictum dignissim vel vitae nibh. Suspendisse pretium ipsum ultricies augue iaculis cursus. In sit amet ex rhoncus, cursus libero ac, interdum neque. Proin vitae consectetur nisi, in sollicitudin sem. Suspendisse sit amet commodo dolor, vel pharetra metus. Proin arcu leo, laoreet placerat erat at, suscipit tempor metus. Sed lacus metus, porttitor a ultrices at, ultrices in massa. Duis cursus accumsan nisi, vitae suscipit libero gravida a.
        Mauris dapibus eros non mi ultricies sagittis. Vivamus vulputate quam eget vehicula consequat. Quisque luctus purus libero, in luctus elit hendrerit at. Nulla facilisi. Nam a purus ornare, lobortis ipsum eget, tincidunt odio. Praesent at ligula at magna efficitur vestibulum. Vestibulum a nisi et neque luctus vestibulum.
        Nunc pharetra ipsum posuere arcu commodo efficitur. Duis blandit quam quis ligula rhoncus, vel pellentesque nunc efficitur. Phasellus vel erat suscipit, vehicula risus a, dictum nulla. Vestibulum sagittis magna magna, consectetur feugiat mauris iaculis non. Aliquam consequat lorem non mauris molestie accumsan. Nulla facilisi. Fusce consequat mi in urna suscipit venenatis. Praesent ut nisl commodo, pharetra lorem sed, congue nunc. Sed tristique euismod orci, vitae viverra arcu dapibus ut. Nunc risus arcu, faucibus eu nunc venenatis, dictum suscipit sem. Vivamus maximus tortor id tellus efficitur fermentum. Lorem ipsum dolor sit amet, consectetur adipiscing elit.
        Aliquam enim justo, fringilla in ullamcorper quis, blandit id orci. Aenean sed quam in nunc elementum suscipit sit amet sit amet libero. Aliquam erat volutpat. Vestibulum eu elit enim. Aenean ante lorem, auctor nec rhoncus sed, finibus eget justo. Quisque at sagittis tellus, eu mattis magna. In bibendum ornare ligula, ut efficitur nunc suscipit sit amet. Vivamus ut nibh quis leo ultrices feugiat eu vitae ex. Nullam rutrum mauris in massa finibus mollis. Ut risus nisi, semper eget ligula ut, elementum semper urna. Morbi commodo finibus euismod. Nulla luctus viverra massa, id rhoncus eros pharetra a..</descricao>
    </documento>
XML;

    file_put_contents($filename, $conteudo);
    echo "Arquivo $filename criado\n";
}