<?php
include "vendor/autoload.php";

use PhpOffice\PhpSpreadsheet\Spreadsheet;

$files = glob('files/*.ods');

foreach ($files as $file) {
    $spreadsheet = \PhpOffice\PhpSpreadsheet\IOFactory::load($file);

    //$cellValue = $spreadsheet->getActiveSheet()->rangeToArray('A1:B5', NULL, FALSE, TRUE, TRUE);
    //$cellValue = $spreadsheet->getActiveSheet()->getCell('A5')->getValue();

    $writer = new \PhpOffice\PhpSpreadsheet\Writer\Csv($spreadsheet);
    $writer->setUseBOM(true);
    $writer->save(basename($file) . ".csv");
}
