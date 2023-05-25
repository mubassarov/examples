<?php
function editDelo() {
    global $authorized, $folder, $delo, $document, $content;

    $result = array(
        'error' => ''
    );

    if ($authorized) {
        if (isset($folder) && checkDigitalValue($folder)) {
            $res = getDeloFields();
            if ($res['error'] == '') {
                $result['number'] = (int) storeDelo(json_encode((object) $res['fields']));
                if ($result['number'] != 0) {
                    $update = isset($delo)?1:0;
                    if ($update) {
                        getDeloFiles();
                    }
                    $delo = (int) $result['number'];
                    readFolderContent();
                    $rights = getRights();
                    foreach ($content['template'] as $template) {
                        $src = getFilePath($template['name'], false);
                        if (file_exists($src)) {
                            $filename = '';
                            if ($update) {
                                foreach ($content['files'] as $file) {
                                    if ($file->{'name'} == $template['code']) {
                                        $filename = $file->{'path'};
                                        break;
                                    }
                                }
                            }
                            if ($filename == '') {
                                $filename = getHashFilename($template['code'], $template['name']);
                            }
                            $dst = getFilePath($filename, true);

                            $data = viewDocument($src, true);
                            $fh = fopen($dst, 'w');
                            fwrite($fh, $data);
                            fclose($fh);

                            $document = '';
                            if (!$update) {
                                linkFile($filename, $template['code']);
                                if ($template['right'] != '') {
                                    foreach (explode(',', $template['right']) as $right) {
                                        $permit = explode(':', $right);
                                        setRight($permit[0], $rights[$permit[1]]['name']);
                                    }
                                }
                            }
                            $document = '';
                        }
                    }
                    appendJurnal($update?"Отредактировано дело":"Создано дело");
                } else {
                    $result['error'] = 'Ошибка при создании дела';
                    unset($result['number']);
                }
            } else {
                $result['error'] = $res['error'];
            }
        } else {
            $result['error'] = 'Не выбрана папка для дела';
        }
    } else {
        $result['error'] = 'Только авторизованный пользователь может создать дело';
    }

    outJSON((object) $result);
}

function getDeloFields() {
    global $content;

    $result = array(
        'error' => ''
    );

    $fields = array();
    $f = array();
    foreach ($content['field'] as $field) {
        if (isset($_POST[$field['code']]) && $_POST[$field['code']] != '') {
            $fields[$field['name']] = $_POST[$field['code']];
        } else {
            array_push($f, $field['name']);
        }
    }

//    if (count($f) == 0) {
        $result['fields'] = $fields;
//    } else {
//        $result['error'] = 'Не заполнены поля: '.implode(', ', $f);
//    }

    return $result;
}

function removeDelo($quiet) {
    global $admin, $folder, $delo;

    $result = array(
        'error' => ''
    );

    if ($admin) {
        if (isset($folder) && checkDigitalValue($folder)) {
            if (isset($delo) && checkDigitalValue($delo)) {
                if (delDelo()) {
                    $result['id'] = $folder;
                    appendJurnal("Удалено дело");
                } else {
                    $result['error'] = 'Ошибка удаления дела';
                }
            } else {
                $result['error'] = 'Не выбрано дело для удаления';
            }
        } else {
            $result['error'] = 'Не выбрана папка с делом';
        }
    } else {
        $result['error'] = 'Только администратор может удалять дела';
    }

    if (!$quiet) {
        outJSON((object) $result);
    }
}

function searchDelo() {
    $list;
    if ($_GET['text']) {
        $list = search($_GET['text']);
    }
    showSearch($list);
}

function getHashFilename($name, $path) {
    global $folder, $delo;

    $path_parts = pathinfo($path);

    return hash('sha256',
            sprintf("%s %d/%d/%s %s",
                microtime(true),
                $folder,
                $delo,
                $path,
                $name),
            false).'.'.$path_parts['extension'];
}

function importDelo() {
    global $authorized, $folder, $delo, $content, $document;

    $result = array(
        'error' => ''
    );

    if ($authorized) {
        if (isset($folder) && checkDigitalValue($folder) && getFolderName() == 'ВХОДЯЩИЕ') {
            if (isset($delo) && checkDigitalValue($delo)) {
                if (checkPostDigitalValue('tofolder') && $_POST['tofolder'] != $folder) {
                    readFolderContent();
                    $from = $folder;
                    $number = $delo;
                    $folder = (int) $_POST['tofolder'];
                    $delo = 0;
                    readFolderFields();
                    $res = getDeloFields();
                    if ($res['error'] == '') {
                        $result['number'] = (int) storeDelo(json_encode((object) $res['fields']));
                        if ($result['number'] != 0) {
                            $result['folder'] = $folder;
                            $delo = $result['number'];
                            foreach ($content['delo'][$number]['files'] as $file) {
                                $src = getFilePath($file->{'path'});
                                if (file_exists($src)) {
                                    linkFile($file->{'path'}, $file->{'name'});
                                    $document = '';
                                }
                            }
                            $folder = $from;
                            $delo = $number;
                            removeDelo(true);
                            $folder = (int) $result['folder'];
                            $delo = (int) $result['number'];
                            appendJurnal("Создано дело");
                        } else {
                            $result['error'] = 'Ошибка при создании дела';
                            unset($result['number']);
                        }
                    } else {
                        $result['error'] = $res['error'];
                    }
                } else {
                    $result['error'] = 'Некорректная папка для импорта дела';
                }
            } else {
                $result['error'] = 'Не выбрано импортируемое дело';
            }
        } else {
            $result['error'] = 'Не выбрана папка "ВХОДЯЩИЕ" для импорта';
        }
    } else {
        $result['error'] = 'Авторизуйтесь для импорта дела';
    }

    outJSON((object) $result);
}
?>