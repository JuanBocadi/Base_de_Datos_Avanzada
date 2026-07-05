### Resultados de Consultas: Diseño de Registros UAI

### 01. Verificación del Trigger (Acumulado de Compras)
| id_cliente | apellido_nombre | id_tipo_documento | nro_documento | acumulado_compras |
| ---------- | --------------- | ----------------- | ------------- | ----------------- |
| 1          | MAURICIO GARCIA | 3                 | 20256997991   | 32500.00          |

### 02. Función: Comprobantes y Base Imponible
| nro_comprobante | fecha      | id_tipo_comprobante | id_cliente | importe  | base_imponible |
| --------------- | ---------- | ------------------- | ---------- | -------- | -------------- |
| 1               | 2023-06-15 | 1                   | 1          | 7500.00  | 6198.35        |
| 2               | 2024-07-16 | 1                   | 1          | 10000.00 | 8264.46        |
| 3               | 2025-08-17 | 1                   | 1          | 15000.00 | 12396.69       |

### 03. Vista Funcional de Comprobantes
| nro_comprobante | fecha      | tipo_comprobante | cliente         | importe  |
| --------------- | ---------- | ---------------- | --------------  | -------- |
| 1               | 2023-06-15 | Factura A        | MAURICIO GARCIA | 7500.00  |
| 2               | 2024-07-16 | Factura A        | MAURICIO GARCIA | 10000.00 |
| 3               | 2025-08-17 | Factura A        | MAURICIO GARCIA | 15000.00 |

### 04. Generación de Archivo de Texto Fijo (118 Caracteres)
| RegistroTXT_118_Caracteres                                                                                               |
| -------------------------------------------------------------------------------------------------------------------------|
| `2023061500100000000000000000001000000000000000000010300000000020256997991MAURICIO GARCIA               000000000750000` |
| `2024071600100000000000000000002000000000000000000020300000000020256997991MAURICIO GARCIA               000000001000000` |
| `2025081700100000000000000000003000000000000000000030300000000020256997991MAURICIO GARCIA               000000001500000` |

### 05. Procedimiento Almacenado: Total Facturado
| TotalFacturado |
| -------------- |
| 32500.00       |