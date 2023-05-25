-- MySQL dump 10.13  Distrib 5.5.15, for Linux (armv5tejl)
--
-- Host: localhost    Database: 
-- ------------------------------------------------------
-- Server version	5.5.15

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Current Database: `erp`
--

CREATE DATABASE /*!32312 IF NOT EXISTS*/ `erp` /*!40100 DEFAULT CHARACTER SET utf8 */;

USE `erp`;

--
-- Table structure for table `buyer`
--

DROP TABLE IF EXISTS `buyer`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `buyer` (
  `BuyerID` int(11) NOT NULL AUTO_INCREMENT,
  `BuyerName` varchar(64) NOT NULL,
  `BuyerAddress` varchar(256) DEFAULT NULL,
  `BuyerNote` text,
  PRIMARY KEY (`BuyerID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `buyer`
--

LOCK TABLES `buyer` WRITE;
/*!40000 ALTER TABLE `buyer` DISABLE KEYS */;
/*!40000 ALTER TABLE `buyer` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `category`
--

DROP TABLE IF EXISTS `category`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `category` (
  `CategoryID` int(11) NOT NULL AUTO_INCREMENT,
  `CategoryName` varchar(64) NOT NULL,
  `CategoryLink` varchar(128) DEFAULT NULL,
  PRIMARY KEY (`CategoryID`)
) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `category`
--

LOCK TABLES `category` WRITE;
/*!40000 ALTER TABLE `category` DISABLE KEYS */;
INSERT INTO `category` VALUES (7,'Одежда для девочек','http://www.odnoklassniki.ru/group/51994631864386/album/51994837975106');
/*!40000 ALTER TABLE `category` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `lot`
--

DROP TABLE IF EXISTS `lot`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `lot` (
  `LotID` int(11) NOT NULL AUTO_INCREMENT,
  `LotName` varchar(64) DEFAULT NULL,
  `LotDescription` varchar(256) DEFAULT NULL,
  `LotPrice` varchar(45) DEFAULT NULL,
  `LotDate` datetime NOT NULL,
  `LotNote` text,
  `CategoryID` int(11) NOT NULL,
  PRIMARY KEY (`LotID`),
  KEY `Date` (`LotDate`) USING BTREE,
  KEY `Price` (`LotPrice`),
  KEY `Name` (`LotName`),
  KEY `Description` (`LotDescription`(255)),
  KEY `fk_lot_category1` (`CategoryID`),
  CONSTRAINT `fk_lot_category1` FOREIGN KEY (`CategoryID`) REFERENCES `category` (`CategoryID`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `lot`
--

LOCK TABLES `lot` WRITE;
/*!40000 ALTER TABLE `lot` DISABLE KEYS */;
INSERT INTO `lot` VALUES (1,'Комплект пиджак+юбка+туника коричневого цвета, хлопок.',NULL,'500','2013-02-24 20:10:33',NULL,7),(2,'Для девочек и мальчиков, размеры 100,110,120,130,140. Хлопок, цв',NULL,'360','2013-02-24 20:57:18',NULL,7),(3,'Платье из хлопка+ туника. размеры 80,90,100.',NULL,'600','2013-02-24 20:58:43',NULL,7),(4,'Элегантное платье 2 цветов, размеры 110, 120, 130, 140.',NULL,'450','2013-02-24 21:01:26',NULL,7);
/*!40000 ALTER TABLE `lot` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `order`
--

DROP TABLE IF EXISTS `order`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `order` (
  `OrderID` int(11) NOT NULL AUTO_INCREMENT,
  `OrderPrice` float DEFAULT NULL,
  `OrderCost` float DEFAULT NULL,
  `OrderStatus` int(11) DEFAULT NULL,
  `OrderNote` text,
  `ProductID` int(11) NOT NULL,
  `PurchaseID` int(11) NOT NULL,
  `BuyerID` int(11) NOT NULL,
  PRIMARY KEY (`OrderID`),
  KEY `fk_order_product1` (`ProductID`),
  KEY `fk_order_purchase1` (`PurchaseID`),
  KEY `fk_order_buyer1` (`BuyerID`),
  CONSTRAINT `fk_order_product1` FOREIGN KEY (`ProductID`) REFERENCES `product` (`ProductID`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `fk_order_purchase1` FOREIGN KEY (`PurchaseID`) REFERENCES `purchase` (`PurchaseID`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `fk_order_buyer1` FOREIGN KEY (`BuyerID`) REFERENCES `buyer` (`BuyerID`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `order`
--

LOCK TABLES `order` WRITE;
/*!40000 ALTER TABLE `order` DISABLE KEYS */;
/*!40000 ALTER TABLE `order` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `product`
--

DROP TABLE IF EXISTS `product`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `product` (
  `ProductID` int(11) NOT NULL AUTO_INCREMENT,
  `ProductName` varchar(128) NOT NULL,
  `ProductDescription` varchar(256) NOT NULL,
  `ProductCode` int(11) NOT NULL,
  `ProductNote` text NOT NULL,
  `ProductPrice` float NOT NULL,
  `ProductDate` datetime NOT NULL,
  `LotID` int(11) NOT NULL,
  `SellerID` int(11) NOT NULL,
  PRIMARY KEY (`ProductID`),
  KEY `Code` (`ProductCode`),
  KEY `Date` (`ProductDate`) USING BTREE,
  KEY `fk_product_lot1` (`LotID`),
  KEY `fk_product_seller1` (`SellerID`),
  CONSTRAINT `fk_product_lot1` FOREIGN KEY (`LotID`) REFERENCES `lot` (`LotID`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `fk_product_seller1` FOREIGN KEY (`SellerID`) REFERENCES `seller` (`SellerID`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `product`
--

LOCK TABLES `product` WRITE;
/*!40000 ALTER TABLE `product` DISABLE KEYS */;
INSERT INTO `product` VALUES (1,'The children set new yarn skirt halter top coat three piece set jacket+shirt+skirt 1pcs free shipping','',671606423,'',13,'2013-02-24 20:10:33',1,1),(2,'Free shipping 2013 new &quot; masha and the bear&quot; T shirts for Children girls and boys  clothes  Age 2-7 Baby clothing','',724636090,'',9.9,'2013-02-24 20:57:18',2,2);
/*!40000 ALTER TABLE `product` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `purchase`
--

DROP TABLE IF EXISTS `purchase`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `purchase` (
  `PurchaseID` int(11) NOT NULL AUTO_INCREMENT,
  `PurchaseDate` date NOT NULL,
  PRIMARY KEY (`PurchaseID`)
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `purchase`
--

LOCK TABLES `purchase` WRITE;
/*!40000 ALTER TABLE `purchase` DISABLE KEYS */;
/*!40000 ALTER TABLE `purchase` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `seller`
--

DROP TABLE IF EXISTS `seller`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `seller` (
  `SellerID` int(11) NOT NULL AUTO_INCREMENT,
  `SellerCode` int(11) NOT NULL,
  `SellerName` varchar(128) NOT NULL,
  `SellerNote` text,
  PRIMARY KEY (`SellerID`),
  KEY `Code` (`SellerCode`),
  KEY `Name` (`SellerName`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `seller`
--

LOCK TABLES `seller` WRITE;
/*!40000 ALTER TABLE `seller` DISABLE KEYS */;
INSERT INTO `seller` VALUES (1,115505,'King&#39;s store - kids mens womens clothing',NULL),(2,614375,'Paiter electrical ',NULL);
/*!40000 ALTER TABLE `seller` ENABLE KEYS */;
UNLOCK TABLES;

/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2013-03-02 20:09:53
