-- --------------------------------------------------------
-- Host:                         161.132.55.120
-- Versión del servidor:         10.4.28-MariaDB - mariadb.org binary distribution
-- SO del servidor:              Win64
-- HeidiSQL Versión:             12.5.0.6677
-- --------------------------------------------------------

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET NAMES utf8 */;
/*!50503 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;


-- Volcando estructura de base de datos para db_controlasistencia
DROP DATABASE IF EXISTS `db_controlasistencia`;
CREATE DATABASE IF NOT EXISTS `db_controlasistencia` /*!40100 DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci */;
USE `db_controlasistencia`;

-- Volcando estructura para procedimiento db_controlasistencia.GenerarReporte
DROP PROCEDURE IF EXISTS `GenerarReporte`;
DELIMITER //
CREATE PROCEDURE `GenerarReporte`(
    IN p_IdArea INT,
    IN p_FechaInicio DATE,
    IN p_FechaFin DATE
)
BEGIN
    DECLARE v_IdReporte INT;

    -- Verificar si ya existe un reporte para el mismo rango de fechas e IdArea
    SELECT IdReporte INTO v_IdReporte
    FROM tb_reporte
    WHERE FechaInicio = p_FechaInicio AND FechaFin = p_FechaFin AND IdArea = p_IdArea
    LIMIT 1;

    -- Si no existe, crear un nuevo reporte
    IF v_IdReporte IS NULL THEN
        INSERT INTO tb_reporte (FechaInicio, FechaFin, IdArea, TotalAsistencias, TotalTardanzas, TotalFaltas)
        VALUES (p_FechaInicio, p_FechaFin, p_IdArea, 0, 0, 0);

        -- Obtener el ID del reporte recién creado
        SET v_IdReporte = LAST_INSERT_ID();
    END IF;

    -- Insertar o actualizar detalles del reporte
    INSERT INTO tb_detallereporte (IdReporte, dniempleado, asistencias, tardanzas, faltas)
    SELECT
        v_IdReporte,
        e.DniEmpleado,
        COUNT(DISTINCT CASE WHEN a.EstadoAsistencia = 'Asistio' THEN a.IdAsistencia END) AS asistencias,
        COUNT(DISTINCT CASE WHEN a.EstadoAsistencia = 'Tardanza' THEN a.IdAsistencia END) AS tardanzas,
        COUNT(DISTINCT CASE WHEN f.IdFalta IS NOT NULL THEN f.IdFalta END) AS faltas
    FROM
        tb_empleado e
        LEFT JOIN tb_asistencia a ON e.DniEmpleado = a.DniEmpleado AND a.FechaAsistencia BETWEEN p_FechaInicio AND p_FechaFin
        LEFT JOIN tb_falta f ON e.DniEmpleado = f.DniEmpleado AND f.FechaFalta BETWEEN p_FechaInicio AND p_FechaFin
    WHERE
        e.IdArea = p_IdArea
    GROUP BY
        e.DniEmpleado;

    -- Actualizar totales en el reporte
    UPDATE tb_reporte
    SET
        TotalAsistencias = (SELECT SUM(asistencias) FROM tb_detallereporte WHERE IdReporte = v_IdReporte),
        TotalTardanzas = (SELECT SUM(tardanzas) FROM tb_detallereporte WHERE IdReporte = v_IdReporte),
        TotalFaltas = (SELECT SUM(faltas) FROM tb_detallereporte WHERE IdReporte = v_IdReporte)
    WHERE
        IdReporte = v_IdReporte;
END//
DELIMITER ;

-- Volcando estructura para tabla db_controlasistencia.tb_area
DROP TABLE IF EXISTS `tb_area`;
CREATE TABLE IF NOT EXISTS `tb_area` (
  `IdArea` int(11) NOT NULL,
  `IdHorario` int(11) DEFAULT NULL,
  `NombreArea` varchar(50) NOT NULL,
  `Descripcion` varchar(200) NOT NULL,
  PRIMARY KEY (`IdArea`),
  KEY `FK_tb_area_tb_horario` (`IdHorario`),
  CONSTRAINT `FK_tb_area_tb_horario` FOREIGN KEY (`IdHorario`) REFERENCES `tb_horario` (`IdHorario`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Volcando datos para la tabla db_controlasistencia.tb_area: ~6 rows (aproximadamente)
INSERT INTO `tb_area` (`IdArea`, `IdHorario`, `NombreArea`, `Descripcion`) VALUES
	(1, 2, 'Area de Venta', 'Encargada de las ventas y atencion al cliente.'),
	(2, 1, 'Area de Produccion', 'Encargada de la produccion de productos.'),
	(3, 1, 'Area de Marketing', 'Encargada de las estrategias de marketing.'),
	(4, 2, 'Area de Limpieza', 'Encargada de la limpieza y mantenimiento.'),
	(5, 2, 'Area de Logistica', 'Encargada de la logistica y distribucion.');

-- Volcando estructura para tabla db_controlasistencia.tb_asistencia
DROP TABLE IF EXISTS `tb_asistencia`;
CREATE TABLE IF NOT EXISTS `tb_asistencia` (
  `IdAsistencia` int(11) NOT NULL AUTO_INCREMENT,
  `DniEmpleado` varchar(8) NOT NULL,
  `FechaAsistencia` date NOT NULL,
  `HoraEntrada` time DEFAULT '00:00:00',
  `HoraSalida` time DEFAULT '00:00:00',
  `EstadoAsistencia` varchar(50) DEFAULT NULL,
  PRIMARY KEY (`IdAsistencia`),
  KEY `DniEmpleado` (`DniEmpleado`),
  CONSTRAINT `tb_asistencia_ibfk_1` FOREIGN KEY (`DniEmpleado`) REFERENCES `tb_empleado` (`DniEmpleado`)
) ENGINE=InnoDB AUTO_INCREMENT=221 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Volcando datos para la tabla db_controlasistencia.tb_asistencia: ~197 rows (aproximadamente)
INSERT INTO `tb_asistencia` (`IdAsistencia`, `DniEmpleado`, `FechaAsistencia`, `HoraEntrada`, `HoraSalida`, `EstadoAsistencia`) VALUES
	(1, '12345678', '2023-09-01', '07:55:00', '16:00:00', 'Cancelada'),
	(2, '23456789', '2023-09-01', '13:55:00', '21:00:00', 'Cancelada'),
	(3, '34567890', '2023-09-01', '07:50:00', '16:00:00', 'Cancelada'),
	(4, '45678901', '2023-09-01', '07:55:00', '16:00:00', 'Cancelada'),
	(5, '56789012', '2023-09-01', '13:55:00', '21:00:00', 'Cancelada'),
	(6, '67890123', '2023-09-01', '07:50:00', '16:00:00', 'Cancelada'),
	(7, '78901234', '2023-09-01', '07:55:00', '16:00:00', 'Cancelada'),
	(8, '89012345', '2023-09-01', '13:55:00', '21:00:00', 'Asistio'),
	(9, '90123456', '2023-09-01', '07:50:00', '16:00:00', 'Asistio'),
	(10, '01234567', '2023-09-01', '07:55:00', '16:00:00', 'Cancelada'),
	(11, '12345098', '2023-09-01', '13:55:00', '21:00:00', 'Asistio'),
	(12, '23456109', '2023-09-01', '07:50:00', '16:00:00', 'Asistio'),
	(13, '34567210', '2023-09-01', '07:55:00', '16:00:00', 'Asistio'),
	(14, '45678321', '2023-09-01', '13:55:00', '21:00:00', 'Asistio'),
	(15, '56789432', '2023-09-01', '07:50:00', '16:00:00', 'Asistio'),
	(16, '12345678', '2023-09-02', '07:55:00', '16:00:00', 'Asistio'),
	(17, '23456789', '2023-09-02', '13:55:00', '21:00:00', 'Asistio'),
	(18, '34567890', '2023-09-02', '07:50:00', '16:00:00', 'Asistio'),
	(19, '45678901', '2023-09-02', '07:55:00', '16:00:00', 'Asistio'),
	(20, '56789012', '2023-09-02', '13:55:00', '21:00:00', 'Asistio'),
	(21, '67890123', '2023-09-02', '07:50:00', '16:00:00', 'Asistio'),
	(22, '78901234', '2023-09-02', '07:55:00', '16:00:00', 'Asistio'),
	(23, '89012345', '2023-09-02', '13:55:00', '21:00:00', 'Asistio'),
	(24, '90123456', '2023-09-02', '07:50:00', '16:00:00', 'Asistio'),
	(25, '01234567', '2023-09-02', '07:55:00', '16:00:00', 'Asistio'),
	(26, '12345098', '2023-09-02', '13:55:00', '21:00:00', 'Asistio'),
	(27, '23456109', '2023-09-02', '07:50:00', '16:00:00', 'Asistio'),
	(28, '34567210', '2023-09-02', '07:55:00', '16:00:00', 'Asistio'),
	(29, '45678321', '2023-09-02', '13:55:00', '21:00:00', 'Asistio'),
	(30, '56789432', '2023-09-02', '07:50:00', '16:00:00', 'Asistio'),
	(31, '12345678', '2023-09-03', '07:55:00', '16:00:00', 'Asistio'),
	(32, '23456789', '2023-09-03', '13:55:00', '21:00:00', 'Asistio'),
	(33, '34567890', '2023-09-03', '07:50:00', '16:00:00', 'Asistio'),
	(34, '45678901', '2023-09-03', '07:55:00', '16:00:00', 'Asistio'),
	(35, '56789012', '2023-09-03', '13:55:00', '21:00:00', 'Asistio'),
	(36, '67890123', '2023-09-03', '07:50:00', '16:00:00', 'Asistio'),
	(37, '78901234', '2023-09-03', '07:55:00', '16:00:00', 'Asistio'),
	(38, '89012345', '2023-09-03', '13:55:00', '21:00:00', 'Asistio'),
	(39, '90123456', '2023-09-03', '07:50:00', '16:00:00', 'Asistio'),
	(40, '01234567', '2023-09-03', '07:55:00', '16:00:00', 'Asistio'),
	(41, '12345098', '2023-09-03', '13:55:00', '21:00:00', 'Asistio'),
	(42, '23456109', '2023-09-03', '07:50:00', '16:00:00', 'Asistio'),
	(43, '34567210', '2023-09-03', '07:55:00', '16:00:00', 'Asistio'),
	(44, '45678321', '2023-09-03', '13:55:00', '21:00:00', 'Asistio'),
	(45, '56789432', '2023-09-03', '07:50:00', '16:00:00', 'Asistio'),
	(46, '12345678', '2023-09-04', '07:55:00', '16:00:00', 'Asistio'),
	(47, '23456789', '2023-09-04', '13:55:00', '21:00:00', 'Asistio'),
	(48, '34567890', '2023-09-04', '07:50:00', '16:00:00', 'Asistio'),
	(49, '45678901', '2023-09-04', '07:55:00', '16:00:00', 'Asistio'),
	(50, '56789012', '2023-09-04', '13:55:00', '21:00:00', 'Asistio'),
	(51, '67890123', '2023-09-04', '07:50:00', '16:00:00', 'Asistio'),
	(52, '78901234', '2023-09-04', '07:55:00', '16:00:00', 'Asistio'),
	(53, '89012345', '2023-09-04', '13:55:00', '21:00:00', 'Asistio'),
	(54, '90123456', '2023-09-04', '07:50:00', '16:00:00', 'Asistio'),
	(55, '01234567', '2023-09-04', '07:55:00', '16:00:00', 'Asistio'),
	(56, '12345098', '2023-09-04', '13:55:00', '21:00:00', 'Cancelada'),
	(57, '23456109', '2023-09-04', '07:50:00', '16:00:00', 'Cancelada'),
	(58, '34567210', '2023-09-04', '07:55:00', '16:00:00', 'Cancelada'),
	(59, '45678321', '2023-09-04', '13:55:00', '21:00:00', 'Cancelada'),
	(60, '56789432', '2023-09-04', '07:50:00', '16:00:00', 'Cancelada'),
	(61, '12345678', '2023-09-05', '07:55:00', '16:00:00', 'Asistio'),
	(62, '23456789', '2023-09-05', '13:55:00', '21:00:00', 'Asistio'),
	(63, '34567890', '2023-09-05', '07:50:00', '16:00:00', 'Asistio'),
	(64, '45678901', '2023-09-05', '07:55:00', '16:00:00', 'Asistio'),
	(65, '56789012', '2023-09-05', '13:55:00', '21:00:00', 'Asistio'),
	(66, '67890123', '2023-09-05', '07:50:00', '16:00:00', 'Asistio'),
	(67, '78901234', '2023-09-05', '07:55:00', '16:00:00', 'Asistio'),
	(68, '89012345', '2023-09-05', '13:55:00', '21:00:00', 'Asistio'),
	(69, '90123456', '2023-09-05', '07:50:00', '16:00:00', 'Asistio'),
	(70, '01234567', '2023-09-05', '07:55:00', '16:00:00', 'Asistio'),
	(71, '12345098', '2023-09-05', '13:55:00', '21:00:00', 'Asistio'),
	(72, '23456109', '2023-09-05', '07:50:00', '16:00:00', 'Asistio'),
	(73, '34567210', '2023-09-05', '07:55:00', '16:00:00', 'Asistio'),
	(74, '45678321', '2023-09-05', '13:55:00', '21:00:00', 'Asistio'),
	(75, '56789432', '2023-09-05', '07:50:00', '16:00:00', 'Asistio'),
	(76, '12345678', '2023-09-06', '07:55:00', '16:00:00', 'Asistio'),
	(77, '23456789', '2023-09-06', '13:55:00', '21:00:00', 'Asistio'),
	(78, '34567890', '2023-09-06', '07:50:00', '16:00:00', 'Asistio'),
	(79, '45678901', '2023-09-06', '07:55:00', '16:00:00', 'Asistio'),
	(80, '56789012', '2023-09-06', '13:55:00', '21:00:00', 'Asistio'),
	(81, '67890123', '2023-09-06', '07:50:00', '16:00:00', 'Asistio'),
	(82, '78901234', '2023-09-06', '07:55:00', '16:00:00', 'Asistio'),
	(83, '89012345', '2023-09-06', '13:55:00', '21:00:00', 'Cancelada'),
	(84, '90123456', '2023-09-06', '07:50:00', '16:00:00', 'Asistio'),
	(85, '01234567', '2023-09-06', '07:55:00', '16:00:00', 'Asistio'),
	(86, '12345098', '2023-09-06', '13:55:00', '21:00:00', 'Asistio'),
	(87, '23456109', '2023-09-06', '07:50:00', '16:00:00', 'Asistio'),
	(88, '34567210', '2023-09-06', '07:55:00', '16:00:00', 'Asistio'),
	(89, '45678321', '2023-09-06', '13:55:00', '21:00:00', 'Asistio'),
	(90, '56789432', '2023-09-06', '07:50:00', '16:00:00', 'Asistio'),
	(91, '12345678', '2023-09-07', '07:55:00', '16:00:00', 'Asistio'),
	(92, '23456789', '2023-09-07', '13:55:00', '21:00:00', 'Asistio'),
	(93, '34567890', '2023-09-07', '07:50:00', '16:00:00', 'Asistio'),
	(94, '45678901', '2023-09-07', '07:55:00', '16:00:00', 'Asistio'),
	(95, '56789012', '2023-09-07', '13:55:00', '21:00:00', 'Asistio'),
	(96, '67890123', '2023-09-07', '07:50:00', '16:00:00', 'Asistio'),
	(97, '78901234', '2023-09-07', '07:55:00', '16:00:00', 'Asistio'),
	(98, '89012345', '2023-09-07', '13:55:00', '21:00:00', 'Asistio'),
	(99, '90123456', '2023-09-07', '07:50:00', '16:00:00', 'Asistio'),
	(100, '01234567', '2023-09-07', '07:55:00', '16:00:00', 'Asistio'),
	(101, '12345098', '2023-09-07', '13:55:00', '21:00:00', 'Asistio'),
	(102, '23456109', '2023-09-07', '07:50:00', '16:00:00', 'Asistio'),
	(103, '34567210', '2023-09-07', '07:55:00', '16:00:00', 'Asistio'),
	(104, '45678321', '2023-09-07', '13:55:00', '21:00:00', 'Asistio'),
	(105, '56789432', '2023-09-07', '07:50:00', '16:00:00', 'Asistio'),
	(106, '12345678', '2023-09-08', '08:05:00', '16:00:00', 'Tardanza'),
	(107, '23456789', '2023-09-08', '14:05:00', '21:00:00', 'Tardanza'),
	(108, '34567890', '2023-09-08', '08:00:00', '16:00:00', 'Asistio'),
	(109, '45678901', '2023-09-08', '08:00:00', '16:00:00', 'Asistio'),
	(110, '56789012', '2023-09-08', '14:00:00', '21:00:00', 'Asistio'),
	(111, '67890123', '2023-09-08', '14:00:00', '21:00:00', 'Asistio'),
	(112, '78901234', '2023-09-08', '08:00:00', '16:00:00', 'Asistio'),
	(113, '89012345', '2023-09-08', '08:00:00', '16:00:00', 'Asistio'),
	(114, '90123456', '2023-09-08', '14:00:00', '21:00:00', 'Asistio'),
	(115, '01234567', '2023-09-08', '14:00:00', '21:00:00', 'Asistio'),
	(116, '12345098', '2023-09-08', '08:00:00', '16:00:00', 'Asistio'),
	(117, '23456109', '2023-09-08', '08:00:00', '16:00:00', 'Asistio'),
	(118, '34567210', '2023-09-08', '14:00:00', '21:00:00', 'Asistio'),
	(119, '45678321', '2023-09-08', '14:00:00', '21:00:00', 'Asistio'),
	(120, '56789432', '2023-09-08', '08:00:00', '16:00:00', 'Cancelada'),
	(121, '44444444', '2023-11-12', '16:55:56', '16:56:36', 'Asistio'),
	(122, '44444444', '2023-11-13', '17:00:22', '17:05:22', 'Asistio'),
	(125, '44444444', '2023-11-14', '00:56:05', '00:00:00', 'Asistio'),
	(126, '77777777', '2023-11-14', '01:00:40', '00:00:00', 'Asistio'),
	(127, '12345678', '2023-11-14', '11:37:03', '00:00:00', 'Cancelada'),
	(128, '70971414', '2023-11-14', '12:06:33', '00:00:00', 'Asistio'),
	(129, '56789432', '2023-11-14', '12:59:14', '00:00:00', 'Asistio'),
	(130, '01234567', '2023-11-14', '13:03:48', '13:05:04', 'Asistio'),
	(131, '44444444', '2023-11-16', '11:03:58', '11:04:34', 'Asistio'),
	(132, '77777777', '2023-11-16', '11:38:08', '22:11:05', 'Asistio'),
	(134, '55555555', '2023-11-16', '11:43:23', '00:00:00', 'Asistio'),
	(135, '01234567', '2023-11-16', '12:00:54', '00:00:00', 'Asistio'),
	(136, '12345098', '2023-11-16', '12:02:27', '00:00:00', 'Asistio'),
	(137, '12345678', '2023-11-16', '12:08:55', '00:00:00', 'Tardanza'),
	(141, '66666666', '2023-11-16', '12:20:30', '00:00:00', 'Asistio'),
	(142, '90123456', '2023-11-16', '12:28:39', '00:00:00', 'Asistio'),
	(143, '89012345', '2023-11-16', '12:30:41', '00:00:00', 'Asistio'),
	(144, '78901234', '2023-11-16', '12:36:31', '00:00:00', 'Tardanza'),
	(145, '70971414', '2023-11-16', '12:37:05', '00:00:00', 'Tardanza'),
	(146, '56789012', '2023-11-16', '12:38:41', '00:00:00', 'Tardanza'),
	(151, '44444444', '2023-11-17', '11:47:06', '00:00:00', 'Tardanza'),
	(152, '77777777', '2023-11-17', '11:47:34', '00:00:00', 'Tardanza'),
	(153, '15151515', '2023-11-17', '11:48:49', '00:00:00', 'Asistio'),
	(154, '12345678', '2023-11-17', '23:03:09', '00:00:00', 'Tardanza'),
	(157, '12345678', '2023-11-27', '12:48:49', '00:00:00', 'Tardanza'),
	(158, '77777777', '2023-11-27', '12:49:03', '00:00:00', 'Tardanza'),
	(159, '44444444', '2023-11-30', '11:50:11', '00:00:00', 'Tardanza'),
	(160, '12345644', '2023-11-30', '16:47:17', '00:00:00', 'Asistio'),
	(161, '77777777', '2023-11-30', '17:36:17', '00:00:00', 'Tardanza'),
	(168, '44444444', '2023-12-04', '10:00:01', '13:12:33', 'Tardanza'),
	(170, '77777777', '2023-12-04', '11:26:01', '17:34:14', 'Asistio'),
	(172, '12345678', '2023-12-04', '11:59:06', '00:00:00', 'Tardanza'),
	(173, '15151515', '2023-12-04', '12:05:20', '00:00:00', 'Asistio'),
	(174, '56789012', '2023-12-04', '12:06:02', '00:00:00', 'Asistio'),
	(176, '78901234', '2023-12-04', '12:19:53', '00:00:00', 'Tardanza'),
	(177, '45678901', '2023-12-04', '12:20:30', '00:00:00', 'Asistio'),
	(178, '66666666', '2023-12-04', '12:22:27', '00:00:00', 'Asistio'),
	(179, '23456789', '2023-12-04', '12:29:46', '00:00:00', 'Tardanza'),
	(180, '34567210', '2023-12-04', '12:30:18', '00:00:00', 'Asistio'),
	(181, '01234567', '2023-12-04', '12:36:32', '00:00:00', 'Asistio'),
	(182, '44444444', '2023-12-06', '12:26:38', '00:00:00', 'Tardanza'),
	(183, '55555555', '2023-12-06', '12:26:58', '00:00:00', 'Asistio'),
	(185, '12345678', '2023-12-06', '12:27:27', '00:00:00', 'Tardanza'),
	(187, '15151515', '2023-12-06', '12:28:00', '12:53:05', 'Asistio'),
	(188, '90123456', '2023-12-06', '12:30:36', '00:00:00', 'Asistio'),
	(189, '55555555', '2023-12-07', '04:06:06', '00:00:00', 'Asistio'),
	(190, '12345678', '2023-12-07', '04:07:37', '07:09:26', 'Asistio'),
	(191, '77777777', '2023-12-07', '04:07:52', '00:00:00', 'Asistio'),
	(192, '44444444', '2023-12-07', '04:09:27', '00:00:00', 'Asistio'),
	(193, '15151515', '2023-12-07', '04:09:36', '17:56:58', 'Asistencia Completa'),
	(194, '01234567', '2023-12-07', '04:15:06', '00:00:00', 'Asistio'),
	(195, '66666666', '2023-12-07', '04:15:16', '00:00:00', 'Asistio'),
	(196, '23456109', '2023-12-07', '06:55:11', '00:00:00', 'Tardanza'),
	(197, '23456789', '2023-12-07', '06:56:26', '00:00:00', 'Tardanza'),
	(198, '25845445', '2023-12-07', '07:07:57', '00:00:00', 'Tardanza'),
	(199, '67890123', '2023-12-07', '07:08:45', '00:00:00', 'Asistio'),
	(200, '56789432', '2023-12-07', '07:09:48', '00:00:00', 'Asistio'),
	(201, '56789012', '2023-12-07', '07:10:16', '00:00:00', 'Asistio'),
	(202, '12345098', '2023-12-07', '07:13:43', '00:00:00', 'Asistio'),
	(203, '70971414', '2023-12-07', '07:25:16', '00:00:00', 'Tardanza'),
	(204, '45678901', '2023-12-07', '07:26:36', '00:00:00', 'Tardanza'),
	(205, '78901234', '2023-12-07', '07:28:11', '00:00:00', 'Asistio'),
	(206, '12355858', '2023-12-07', '07:28:58', '00:00:00', 'Tardanza'),
	(207, '45678321', '2023-12-07', '07:32:45', '00:00:00', 'Asistio'),
	(208, '34567890', '2023-12-07', '07:32:59', '00:00:00', 'Asistio'),
	(209, '90123456', '2023-12-07', '07:33:30', '00:00:00', 'Tardanza'),
	(210, '01234567', '2023-12-08', '00:38:01', '00:39:31', 'Asistencia Completa'),
	(211, '15151515', '2023-12-08', '02:32:09', '00:00:00', 'Marco Entrada'),
	(212, '44444444', '2023-12-08', '11:01:29', '11:11:44', 'Asistencia Completa'),
	(213, '77777777', '2023-12-08', '11:02:01', '00:00:00', 'Marco Entrada'),
	(214, '12345678', '2023-12-08', '11:09:29', '00:00:00', 'Marco Entrada'),
	(215, '66666666', '2023-12-08', '12:47:57', '00:00:00', 'Marco Entrada'),
	(216, '34567210', '2023-12-08', '13:23:42', '00:00:00', 'Marco Entrada'),
	(217, '34567890', '2023-12-08', '13:24:08', '00:00:00', 'Marco Entrada'),
	(218, '55555555', '2023-12-08', '13:42:21', '00:00:00', 'Marco Entrada'),
	(219, '89012345', '2023-12-08', '14:02:24', '00:00:00', 'Marco Entrada'),
	(220, '56789012', '2023-12-08', '16:40:59', '16:41:59', 'Asistencia Completa');

-- Volcando estructura para tabla db_controlasistencia.tb_detallereporte
DROP TABLE IF EXISTS `tb_detallereporte`;
CREATE TABLE IF NOT EXISTS `tb_detallereporte` (
  `iddetalle` int(11) NOT NULL AUTO_INCREMENT,
  `idreporte` int(11) DEFAULT NULL,
  `dniempleado` varchar(8) DEFAULT NULL,
  `asistencias` int(11) DEFAULT NULL,
  `tardanzas` int(11) DEFAULT NULL,
  `faltas` int(11) DEFAULT NULL,
  PRIMARY KEY (`iddetalle`),
  KEY `FK__tb_reportemensual` (`idreporte`),
  KEY `FK__tb_empleado` (`dniempleado`),
  CONSTRAINT `FK__tb_empleado` FOREIGN KEY (`dniempleado`) REFERENCES `tb_empleado` (`DniEmpleado`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `FK__tb_reportemensual` FOREIGN KEY (`idreporte`) REFERENCES `tb_reporte` (`IdReporte`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB AUTO_INCREMENT=66 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Volcando datos para la tabla db_controlasistencia.tb_detallereporte: ~33 rows (aproximadamente)
INSERT INTO `tb_detallereporte` (`iddetalle`, `idreporte`, `dniempleado`, `asistencias`, `tardanzas`, `faltas`) VALUES
	(25, 14, '12345098', 1, 0, 0),
	(26, 14, '12345678', 1, 2, 0),
	(27, 14, '67890123', 1, 0, 0),
	(28, 14, '12345098', 1, 0, 0),
	(29, 14, '12345678', 1, 2, 0),
	(30, 14, '67890123', 1, 0, 0),
	(31, 15, '01234567', 2, 0, 0),
	(32, 15, '56789012', 2, 0, 0),
	(33, 15, '56789432', 1, 0, 0),
	(34, 15, '70971414', 0, 1, 0),
	(35, 15, '77777777', 2, 0, 0),
	(38, 16, '12345644', 0, 0, 0),
	(39, 16, '12355859', 0, 0, 0),
	(40, 16, '15151515', 2, 0, 0),
	(41, 16, '34567210', 1, 0, 0),
	(42, 16, '34567890', 1, 0, 0),
	(43, 16, '55555555', 2, 0, 0),
	(44, 16, '89012345', 0, 0, 0),
	(45, 17, '01234567', 2, 0, 0),
	(46, 17, '56789012', 0, 1, 0),
	(47, 17, '56789432', 1, 0, 0),
	(48, 17, '70971414', 1, 1, 0),
	(49, 17, '77777777', 2, 3, 0),
	(52, 18, '23456109', 7, 1, 0),
	(53, 18, '23456789', 6, 3, 0),
	(54, 18, '25845445', 0, 1, 0),
	(55, 18, '44444444', 5, 4, 0),
	(56, 18, '78901234', 8, 2, 0),
	(59, 19, '12355858', 0, 0, 0),
	(60, 19, '45678321', 0, 0, 0),
	(61, 19, '45678901', 0, 0, 0),
	(62, 19, '66666666', 1, 0, 0),
	(63, 19, '90123456', 1, 0, 0);

-- Volcando estructura para tabla db_controlasistencia.tb_empleado
DROP TABLE IF EXISTS `tb_empleado`;
CREATE TABLE IF NOT EXISTS `tb_empleado` (
  `DniEmpleado` varchar(8) NOT NULL,
  `IdArea` int(11) NOT NULL,
  `Nombre` varchar(100) NOT NULL,
  `Apellido` varchar(100) NOT NULL,
  `Puesto` varchar(100) NOT NULL,
  `Telefono` varchar(20) DEFAULT NULL,
  `Genero` varchar(50) DEFAULT NULL,
  `Estado` varchar(50) DEFAULT NULL,
  `Foto` varchar(250) DEFAULT NULL,
  `IdUsuario` int(11) DEFAULT NULL,
  PRIMARY KEY (`DniEmpleado`),
  KEY `IdArea` (`IdArea`),
  KEY `FK_tb_empleado_tb_usuario` (`IdUsuario`),
  CONSTRAINT `FK_tb_empleado_tb_usuario` FOREIGN KEY (`IdUsuario`) REFERENCES `tb_usuario` (`IdUsuario`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `tb_empleado_ibfk_1` FOREIGN KEY (`IdArea`) REFERENCES `tb_area` (`IdArea`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Volcando datos para la tabla db_controlasistencia.tb_empleado: ~25 rows (aproximadamente)
INSERT INTO `tb_empleado` (`DniEmpleado`, `IdArea`, `Nombre`, `Apellido`, `Puesto`, `Telefono`, `Genero`, `Estado`, `Foto`, `IdUsuario`) VALUES
	('01234567', 5, 'Elena', 'Perez', 'LogÃ­stica', '55556789', 'Femenino', 'Activo', 'https://i.ibb.co/kJZ2k2Y/hueso.jpg', NULL),
	('12345098', 1, 'Mario', 'Gutierrez', 'Vendedor', '555-1234', 'Masculino', 'A', 'https://i.ibb.co/kJZ2k2Y/hueso.jpg', NULL),
	('12345644', 3, 'Elias', 'Campos', 'Vendedor', '984141222', 'Masculino', 'Activo', 'https://i.ibb.co/kJZ2k2Y/hueso.jpg', NULL),
	('12345678', 1, 'Juan', 'Perez', 'Vendedor', '555-1234', 'Masculino', 'A', 'https://i.ibb.co/kJZ2k2Y/hueso.jpg', 4),
	('12355858', 4, 'Mufasa', 'acascac', 'Limpiador', '123141241', 'Femenino', 'a', 'https://i.ibb.co/kJZ2k2Y/hueso.jpg', NULL),
	('12355859', 3, 'acfadsa', 'acascac', 'qwfasfa', '123141241', 'Masculino', 'a', 'https://i.ibb.co/kJZ2k2Y/hueso.jpg', NULL),
	('15151515', 3, 'Mariela', 'Hugarte Perez', 'Jefa', '984494961', 'Femenino', 'Activa', 'https://i.ibb.co/kJZ2k2Y/hueso.jpg', NULL),
	('23456109', 2, 'Laura', 'Mendoza', 'Operaria', '555-5678', 'Femenino', 'A', 'https://i.ibb.co/kJZ2k2Y/hueso.jpg', NULL),
	('23456789', 2, 'Maria', 'Gomez', 'Operario', '555-5678', 'Femenino', 'A', 'https://i.ibb.co/kJZ2k2Y/hueso.jpg', NULL),
	('25845445', 2, 'Juanito', 'Perez', 'Logistica', '983928222', 'Masculino', 'A', 'https://i.ibb.co/kJZ2k2Y/hueso.jpg', NULL),
	('34567210', 3, 'Pedro', 'Rodriguez', 'Marketero', '555-9012', 'Masculino', 'A', 'https://i.ibb.co/kJZ2k2Y/hueso.jpg', NULL),
	('34567890', 3, 'Luis', 'Martinez', 'Marketero', '555-9012', 'Masculino', 'A', 'https://i.ibb.co/kJZ2k2Y/hueso.jpg', NULL),
	('44444444', 2, 'Pablo', 'Marlom', 'Operario', '983928222', 'Masculino', 'A', 'https://i.ibb.co/kJZ2k2Y/hueso.jpg', 2),
	('45678321', 4, 'Marta', 'Garcia', 'Limpiadora', '555-2345', 'Femenino', 'A', 'https://i.ibb.co/kJZ2k2Y/hueso.jpg', NULL),
	('45678901', 4, 'Laura', 'Lopez', 'Limpiadora', '555-2345', 'Femenino', 'A', 'https://i.ibb.co/kJZ2k2Y/hueso.jpg', NULL),
	('55555555', 3, 'Marcos', 'Campos', 'Vendedor', '983928233', 'Masculino', 'A', 'https://i.ibb.co/kJZ2k2Y/hueso.jpg', NULL),
	('56789012', 5, 'Pedro', 'Gonzalez', 'Logístico', '555-6789', 'Masculino', 'A', 'https://i.ibb.co/kJZ2k2Y/hueso.jpg', NULL),
	('56789432', 5, 'Javier', 'Lopez', 'Logístico', '555-6789', 'Masculino', 'A', 'https://i.ibb.co/kJZ2k2Y/hueso.jpg', NULL),
	('66666666', 4, 'Yesica', 'Diaz', 'Limpiador', '983928244', 'Femenino', 'A', 'https://i.ibb.co/kJZ2k2Y/hueso.jpg', 5),
	('67890123', 1, 'Ana', 'Rodriguez', 'Vendedora', '555-1234', 'Femenino', 'A', 'https://i.ibb.co/kJZ2k2Y/hueso.jpg', NULL),
	('70971414', 5, 'Christian', 'Ponce', 'Logistica', '4447844', 'Masculino', 'A', 'https://i.ibb.co/kJZ2k2Y/hueso.jpg', NULL),
	('77777777', 5, 'Piero', 'Flores', 'Logistica', '983928255', 'Masculino', 'A', 'https://i.ibb.co/kJZ2k2Y/hueso.jpg', 3),
	('78901234', 2, 'Carlos', 'Hernandez', 'Operario', '555-5678', 'Masculino', 'A', 'https://i.ibb.co/kJZ2k2Y/hueso.jpg', NULL),
	('89012345', 3, 'Sofia', 'Diaz', 'Marketera', '555999012', 'Femenino', 'Activo', 'https://i.ibb.co/kJZ2k2Y/hueso.jpg', NULL),
	('90123456', 4, 'Diego', 'Sanchez', 'Limpiador', '555992345', 'Masculino', 'Activo', 'https://i.ibb.co/kJZ2k2Y/hueso.jpg', NULL);

-- Volcando estructura para tabla db_controlasistencia.tb_falta
DROP TABLE IF EXISTS `tb_falta`;
CREATE TABLE IF NOT EXISTS `tb_falta` (
  `IdFalta` int(11) NOT NULL AUTO_INCREMENT,
  `DniEmpleado` varchar(8) NOT NULL,
  `FechaFalta` date NOT NULL,
  PRIMARY KEY (`IdFalta`),
  KEY `DniEmpleado` (`DniEmpleado`),
  CONSTRAINT `tb_falta_ibfk_1` FOREIGN KEY (`DniEmpleado`) REFERENCES `tb_empleado` (`DniEmpleado`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Volcando datos para la tabla db_controlasistencia.tb_falta: ~0 rows (aproximadamente)

-- Volcando estructura para tabla db_controlasistencia.tb_horario
DROP TABLE IF EXISTS `tb_horario`;
CREATE TABLE IF NOT EXISTS `tb_horario` (
  `IdHorario` int(11) NOT NULL AUTO_INCREMENT,
  `NombreHorario` varchar(50) DEFAULT NULL,
  `FechaInicio` date DEFAULT NULL,
  `FechaFin` date DEFAULT NULL,
  `HoraEntrada` time NOT NULL,
  `HoraSalida` time NOT NULL,
  PRIMARY KEY (`IdHorario`)
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Volcando datos para la tabla db_controlasistencia.tb_horario: ~3 rows (aproximadamente)
INSERT INTO `tb_horario` (`IdHorario`, `NombreHorario`, `FechaInicio`, `FechaFin`, `HoraEntrada`, `HoraSalida`) VALUES
	(1, 'OFICINA', '2023-01-01', '2024-01-01', '08:00:00', '16:00:00'),
	(2, 'CAMPO', '2023-01-01', '2023-12-31', '06:00:00', '18:00:00'),
	(10, 'CAMPO TECNICO', '2023-12-01', '2023-12-31', '08:00:00', '17:00:00');

-- Volcando estructura para tabla db_controlasistencia.tb_reporte
DROP TABLE IF EXISTS `tb_reporte`;
CREATE TABLE IF NOT EXISTS `tb_reporte` (
  `IdReporte` int(11) NOT NULL AUTO_INCREMENT,
  `FechaInicio` date DEFAULT NULL,
  `FechaFin` date DEFAULT NULL,
  `IdArea` int(11) NOT NULL,
  `TotalAsistencias` int(11) NOT NULL,
  `TotalTardanzas` int(11) NOT NULL,
  `TotalFaltas` int(11) NOT NULL,
  PRIMARY KEY (`IdReporte`),
  KEY `IdArea` (`IdArea`),
  CONSTRAINT `tb_reporte_ibfk_1` FOREIGN KEY (`IdArea`) REFERENCES `tb_area` (`IdArea`)
) ENGINE=InnoDB AUTO_INCREMENT=20 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Volcando datos para la tabla db_controlasistencia.tb_reporte: ~7 rows (aproximadamente)
INSERT INTO `tb_reporte` (`IdReporte`, `FechaInicio`, `FechaFin`, `IdArea`, `TotalAsistencias`, `TotalTardanzas`, `TotalFaltas`) VALUES
	(1, '2023-01-01', '2023-01-31', 1, 50, 5, 3),
	(14, '2023-12-01', '2023-12-31', 1, 6, 4, 0),
	(15, '2023-12-01', '2023-12-31', 5, 7, 1, 0),
	(16, '2023-12-01', '2023-12-09', 3, 6, 0, 0),
	(17, '2023-11-01', '2023-11-30', 5, 6, 5, 0),
	(18, '2023-09-01', '2023-12-31', 2, 26, 11, 0),
	(19, '2023-11-01', '2023-11-30', 4, 2, 0, 0);

-- Volcando estructura para tabla db_controlasistencia.tb_tardanza
DROP TABLE IF EXISTS `tb_tardanza`;
CREATE TABLE IF NOT EXISTS `tb_tardanza` (
  `IdTardanza` int(11) NOT NULL AUTO_INCREMENT,
  `IdAsistencia` int(11) NOT NULL,
  `MinutosTardanza` int(11) NOT NULL,
  PRIMARY KEY (`IdTardanza`),
  KEY `IdAsistencia` (`IdAsistencia`),
  CONSTRAINT `tb_tardanza_ibfk_1` FOREIGN KEY (`IdAsistencia`) REFERENCES `tb_asistencia` (`IdAsistencia`)
) ENGINE=InnoDB AUTO_INCREMENT=38 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Volcando datos para la tabla db_controlasistencia.tb_tardanza: ~36 rows (aproximadamente)
INSERT INTO `tb_tardanza` (`IdTardanza`, `IdAsistencia`, `MinutosTardanza`) VALUES
	(1, 106, 5),
	(2, 107, 5),
	(4, 137, 248),
	(5, 144, 216),
	(6, 145, 277),
	(7, 146, 278),
	(8, 151, 167),
	(9, 152, 227),
	(10, 154, 903),
	(11, 157, 288),
	(12, 158, 289),
	(13, 159, 170),
	(14, 161, 576),
	(15, 168, 60),
	(16, 172, 239),
	(17, 176, 199),
	(18, 179, 209),
	(19, 182, 206),
	(20, 185, 267),
	(21, 196, 55),
	(22, 197, 56),
	(23, 198, 67),
	(24, 203, 85),
	(25, 204, 86),
	(26, 206, 88),
	(27, 207, 92),
	(28, 209, 93),
	(29, 212, 181),
	(30, 213, 302),
	(31, 214, 309),
	(32, 215, 407),
	(33, 216, 323),
	(34, 217, 324),
	(35, 218, 342),
	(36, 219, 362),
	(37, 220, 640);

-- Volcando estructura para tabla db_controlasistencia.tb_usuario
DROP TABLE IF EXISTS `tb_usuario`;
CREATE TABLE IF NOT EXISTS `tb_usuario` (
  `IdUsuario` int(11) NOT NULL AUTO_INCREMENT,
  `Nombre` varchar(30) NOT NULL,
  `Clave` varchar(20) NOT NULL,
  `Nivel` varchar(15) NOT NULL,
  PRIMARY KEY (`IdUsuario`),
  UNIQUE KEY `Nombre` (`Nombre`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Volcando datos para la tabla db_controlasistencia.tb_usuario: ~5 rows (aproximadamente)
INSERT INTO `tb_usuario` (`IdUsuario`, `Nombre`, `Clave`, `Nivel`) VALUES
	(1, 'admin', '1234', 'Administrador'),
	(2, 'emp001', '1234', 'Empleado'),
	(3, 'emp002', '1234', 'Empleado'),
	(4, 'emp003', '1234', 'Empleado'),
	(5, 'emp005', '1234', 'Empleado');

/*!40103 SET TIME_ZONE=IFNULL(@OLD_TIME_ZONE, 'system') */;
/*!40101 SET SQL_MODE=IFNULL(@OLD_SQL_MODE, '') */;
/*!40014 SET FOREIGN_KEY_CHECKS=IFNULL(@OLD_FOREIGN_KEY_CHECKS, 1) */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40111 SET SQL_NOTES=IFNULL(@OLD_SQL_NOTES, 1) */;
