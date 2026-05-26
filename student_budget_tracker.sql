-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: May 26, 2026 at 02:24 PM
-- Server version: 10.4.32-MariaDB
-- PHP Version: 8.2.12

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `student_budget_tracker`
--

DELIMITER $$
--
-- Procedures
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_get_transactions_by_filter` (IN `p_userid` INT, IN `p_from` DATE, IN `p_to` DATE, IN `p_role` VARCHAR(10))   BEGIN
  -- This returns both income and expense rows with user info; uses LEFT JOIN (outer)
  SELECT t.*
  FROM vw_transactions_category t
  WHERE (p_userid IS NULL OR t.UserID = p_userid)
    AND (p_from IS NULL OR t.Date >= p_from)
    AND (p_to IS NULL OR t.Date <= p_to)
    AND (p_role IS NULL OR EXISTS(SELECT 1 FROM Users u WHERE u.UserID = t.UserID AND u.Role = p_role))
  ORDER BY t.Date DESC;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_get_user_monthly_report` (IN `p_userid` INT, IN `p_year` INT, IN `p_month` INT)   BEGIN
  SELECT r.ReportID, r.UserID, u.Name, r.Month, r.Year, r.TotalIncome, r.TotalExpense, r.Balance
  FROM Reports r
  INNER JOIN Users u ON r.UserID = u.UserID
  WHERE (p_userid IS NULL OR r.UserID = p_userid)
    AND (p_year IS NULL OR r.Year = p_year)
    AND (p_month IS NULL OR r.Month = p_month)
  ORDER BY r.Year DESC, r.Month DESC;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_monthly_aggregates_by_user` (IN `p_userid` INT, IN `p_year` INT)   BEGIN
  SELECT 
    u.UserID,
    u.Name,
    COALESCE(SUM(CASE WHEN ct.CategoryType = 'Income' THEN t.Amount END),0) AS TotalIncome,
    COALESCE(SUM(CASE WHEN ct.CategoryType = 'Expense' THEN t.Amount END),0) AS TotalExpense
  FROM (
      SELECT i.UserID, i.Amount, i.Date, c.CategoryType FROM Income i JOIN Categories c ON i.CategoryID = c.CategoryID
      UNION ALL
      SELECT e.UserID, e.Amount, e.Date, c.CategoryType FROM Expenses e JOIN Categories c ON e.CategoryID = c.CategoryID
  ) t
  JOIN Users u ON t.UserID = u.UserID
  LEFT JOIN Categories c2 ON c2.CategoryID = NULL -- no-op, left to demonstrate OUTER usage if needed
  LEFT JOIN CategoryTypes ct ON t.CategoryType = ct.CategoryType
  WHERE (p_userid IS NULL OR u.UserID = p_userid)
    AND (p_year IS NULL OR YEAR(t.Date) = p_year)
  GROUP BY u.UserID, u.Name;
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `budgets`
--

CREATE TABLE `budgets` (
  `BudgetID` int(11) NOT NULL,
  `UserID` int(11) NOT NULL,
  `CategoryID` int(11) NOT NULL,
  `LimitAmount` decimal(10,2) NOT NULL,
  `SpentOverride` decimal(10,2) DEFAULT 0.00,
  `Month` int(11) NOT NULL CHECK (`Month` between 1 and 12),
  `Year` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `budgets`
--

INSERT INTO `budgets` (`BudgetID`, `UserID`, `CategoryID`, `LimitAmount`, `SpentOverride`, `Month`, `Year`) VALUES
(1, 2, 2, 6000.00, 7000.00, 1, 2026);

-- --------------------------------------------------------

--
-- Table structure for table `categories`
--

CREATE TABLE `categories` (
  `CategoryID` int(11) NOT NULL,
  `Name` varchar(100) NOT NULL,
  `CategoryType` varchar(10) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `categories`
--

INSERT INTO `categories` (`CategoryID`, `Name`, `CategoryType`) VALUES
(1, 'Salary', 'Income'),
(2, 'Allowance', 'Income'),
(3, 'Food', 'Expense'),
(4, 'Transport', 'Expense'),
(5, 'Books', 'Expense');

-- --------------------------------------------------------

--
-- Table structure for table `categorytypes`
--

CREATE TABLE `categorytypes` (
  `CategoryType` varchar(10) NOT NULL CHECK (`CategoryType` in ('Income','Expense'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `categorytypes`
--

INSERT INTO `categorytypes` (`CategoryType`) VALUES
('Expense'),
('Income');

-- --------------------------------------------------------

--
-- Table structure for table `expenses`
--

CREATE TABLE `expenses` (
  `ExpenseID` int(11) NOT NULL,
  `UserID` int(11) NOT NULL,
  `CategoryID` int(11) NOT NULL,
  `Amount` decimal(10,2) NOT NULL,
  `Date` date NOT NULL,
  `Description` varchar(255) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `expenses`
--

INSERT INTO `expenses` (`ExpenseID`, `UserID`, `CategoryID`, `Amount`, `Date`, `Description`) VALUES
(1, 2, 3, 3000.00, '2026-01-12', 'ytugfyiughiugi9y'),
(2, 2, 3, 1999.99, '2025-12-17', 'rdyuyfutygiygfytfuyfuyf'),
(3, 2, 3, 700.00, '2025-11-21', 'gubiuhviugvuyhguohoi');

-- --------------------------------------------------------

--
-- Table structure for table `income`
--

CREATE TABLE `income` (
  `IncomeID` int(11) NOT NULL,
  `UserID` int(11) NOT NULL,
  `Amount` decimal(10,2) NOT NULL,
  `CategoryID` int(11) NOT NULL,
  `Date` date NOT NULL,
  `Description` varchar(255) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `income`
--

INSERT INTO `income` (`IncomeID`, `UserID`, `Amount`, `CategoryID`, `Date`, `Description`) VALUES
(1, 2, 7000.00, 2, '2026-01-16', 'tygyviy'),
(2, 2, 3000.00, 1, '2025-12-23', 'fcguioibuyfiuhiogfuyfi'),
(3, 2, 8000.00, 2, '2025-11-18', 'gubiuhviugvuyhguohoi'),
(4, 2, 15000.00, 2, '2025-10-22', 'gubiuhviugvuyhguohoi'),
(5, 2, 54889.00, 1, '2026-05-13', 'gubiuhviugvuyhguohoifefwe');

-- --------------------------------------------------------

--
-- Table structure for table `messages`
--

CREATE TABLE `messages` (
  `MessageID` int(11) NOT NULL,
  `SenderID` int(11) NOT NULL,
  `ReceiverID` int(11) NOT NULL,
  `MessageText` text NOT NULL,
  `SentAt` datetime DEFAULT current_timestamp(),
  `IsRead` tinyint(1) DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `notifications`
--

CREATE TABLE `notifications` (
  `NotificationID` int(11) NOT NULL,
  `UserID` int(11) NOT NULL,
  `SenderID` int(11) DEFAULT NULL,
  `Title` varchar(255) NOT NULL,
  `Message` text NOT NULL,
  `DateCreated` datetime DEFAULT current_timestamp(),
  `IsRead` tinyint(1) DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `reports`
--

CREATE TABLE `reports` (
  `ReportID` int(11) NOT NULL,
  `UserID` int(11) NOT NULL,
  `Month` int(11) NOT NULL CHECK (`Month` between 1 and 12),
  `Year` int(11) NOT NULL,
  `TotalIncome` decimal(10,2) DEFAULT 0.00,
  `TotalExpense` decimal(10,2) DEFAULT 0.00,
  `Balance` decimal(10,2) DEFAULT 0.00
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `users`
--

CREATE TABLE `users` (
  `UserID` int(11) NOT NULL,
  `Name` varchar(100) NOT NULL,
  `Email` varchar(100) NOT NULL,
  `Password` varchar(255) NOT NULL,
  `StudentID` varchar(50) DEFAULT NULL,
  `Role` enum('student','staff','admin') NOT NULL DEFAULT 'student',
  `DarkMode` tinyint(1) DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `users`
--

INSERT INTO `users` (`UserID`, `Name`, `Email`, `Password`, `StudentID`, `Role`, `DarkMode`) VALUES
(1, 'System Admin', 'admin@tracker.com', '$2y$10$examplehashforadmin', NULL, 'admin', 0),
(2, 'Ravhura Thanzi', 'ravhurathanzi26@gmail.com', '$2y$10$FxkwMSmaEqGGhVpm18rUg.6SyTCvFKKewcaYuvyQRbRzITT54NjA2', '0312215629089', 'student', 0);

-- --------------------------------------------------------

--
-- Stand-in structure for view `vw_monthly_summary`
-- (See below for the actual view)
--
CREATE TABLE `vw_monthly_summary` (
`UserID` int(11)
,`Name` varchar(100)
,`Year` int(11)
,`Month` int(11)
,`TotalIncome` decimal(10,2)
,`TotalExpense` decimal(10,2)
,`Balance` decimal(10,2)
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `vw_transactions_category`
-- (See below for the actual view)
--
CREATE TABLE `vw_transactions_category` (
`type` varchar(7)
,`txnID` int(11)
,`UserID` int(11)
,`Name` varchar(100)
,`Amount` decimal(10,2)
,`CategoryName` varchar(100)
,`CategoryType` varchar(10)
,`Date` date
,`Description` varchar(255)
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `vw_users_reports_full`
-- (See below for the actual view)
--
CREATE TABLE `vw_users_reports_full` (
`UserID` int(11)
,`Name` varchar(100)
,`ReportID` int(11)
,`Year` int(11)
,`Month` int(11)
,`TotalIncome` decimal(10,2)
,`TotalExpense` decimal(10,2)
);

-- --------------------------------------------------------

--
-- Structure for view `vw_monthly_summary`
--
DROP TABLE IF EXISTS `vw_monthly_summary`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vw_monthly_summary`  AS SELECT `u`.`UserID` AS `UserID`, `u`.`Name` AS `Name`, `r`.`Year` AS `Year`, `r`.`Month` AS `Month`, ifnull(`r`.`TotalIncome`,0) AS `TotalIncome`, ifnull(`r`.`TotalExpense`,0) AS `TotalExpense`, ifnull(`r`.`Balance`,0) AS `Balance` FROM (`reports` `r` join `users` `u` on(`r`.`UserID` = `u`.`UserID`)) ;

-- --------------------------------------------------------

--
-- Structure for view `vw_transactions_category`
--
DROP TABLE IF EXISTS `vw_transactions_category`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vw_transactions_category`  AS SELECT 'income' AS `type`, `i`.`IncomeID` AS `txnID`, `i`.`UserID` AS `UserID`, `u`.`Name` AS `Name`, `i`.`Amount` AS `Amount`, `c`.`Name` AS `CategoryName`, `ct`.`CategoryType` AS `CategoryType`, `i`.`Date` AS `Date`, `i`.`Description` AS `Description` FROM (((`income` `i` left join `categories` `c` on(`i`.`CategoryID` = `c`.`CategoryID`)) left join `categorytypes` `ct` on(`c`.`CategoryType` = `ct`.`CategoryType`)) left join `users` `u` on(`i`.`UserID` = `u`.`UserID`))union all select 'expense' AS `type`,`e`.`ExpenseID` AS `txnID`,`e`.`UserID` AS `UserID`,`u`.`Name` AS `Name`,`e`.`Amount` AS `Amount`,`c`.`Name` AS `CategoryName`,`ct`.`CategoryType` AS `CategoryType`,`e`.`Date` AS `Date`,`e`.`Description` AS `Description` from (((`expenses` `e` left join `categories` `c` on(`e`.`CategoryID` = `c`.`CategoryID`)) left join `categorytypes` `ct` on(`c`.`CategoryType` = `ct`.`CategoryType`)) left join `users` `u` on(`e`.`UserID` = `u`.`UserID`))  ;

-- --------------------------------------------------------

--
-- Structure for view `vw_users_reports_full`
--
DROP TABLE IF EXISTS `vw_users_reports_full`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vw_users_reports_full`  AS SELECT `u`.`UserID` AS `UserID`, `u`.`Name` AS `Name`, `r`.`ReportID` AS `ReportID`, `r`.`Year` AS `Year`, `r`.`Month` AS `Month`, `r`.`TotalIncome` AS `TotalIncome`, `r`.`TotalExpense` AS `TotalExpense` FROM (`users` `u` left join `reports` `r` on(`u`.`UserID` = `r`.`UserID`))union select `u`.`UserID` AS `UserID`,`u`.`Name` AS `Name`,`r`.`ReportID` AS `ReportID`,`r`.`Year` AS `Year`,`r`.`Month` AS `Month`,`r`.`TotalIncome` AS `TotalIncome`,`r`.`TotalExpense` AS `TotalExpense` from (`reports` `r` left join `users` `u` on(`u`.`UserID` = `r`.`UserID`))  ;

--
-- Indexes for dumped tables
--

--
-- Indexes for table `budgets`
--
ALTER TABLE `budgets`
  ADD PRIMARY KEY (`BudgetID`),
  ADD KEY `UserID` (`UserID`),
  ADD KEY `CategoryID` (`CategoryID`);

--
-- Indexes for table `categories`
--
ALTER TABLE `categories`
  ADD PRIMARY KEY (`CategoryID`),
  ADD KEY `CategoryType` (`CategoryType`);

--
-- Indexes for table `categorytypes`
--
ALTER TABLE `categorytypes`
  ADD PRIMARY KEY (`CategoryType`);

--
-- Indexes for table `expenses`
--
ALTER TABLE `expenses`
  ADD PRIMARY KEY (`ExpenseID`),
  ADD KEY `UserID` (`UserID`),
  ADD KEY `CategoryID` (`CategoryID`);

--
-- Indexes for table `income`
--
ALTER TABLE `income`
  ADD PRIMARY KEY (`IncomeID`),
  ADD KEY `UserID` (`UserID`),
  ADD KEY `CategoryID` (`CategoryID`);

--
-- Indexes for table `messages`
--
ALTER TABLE `messages`
  ADD PRIMARY KEY (`MessageID`),
  ADD KEY `SenderID` (`SenderID`),
  ADD KEY `ReceiverID` (`ReceiverID`);

--
-- Indexes for table `notifications`
--
ALTER TABLE `notifications`
  ADD PRIMARY KEY (`NotificationID`),
  ADD KEY `UserID` (`UserID`),
  ADD KEY `SenderID` (`SenderID`);

--
-- Indexes for table `reports`
--
ALTER TABLE `reports`
  ADD PRIMARY KEY (`ReportID`),
  ADD KEY `UserID` (`UserID`);

--
-- Indexes for table `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`UserID`),
  ADD UNIQUE KEY `Email` (`Email`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `budgets`
--
ALTER TABLE `budgets`
  MODIFY `BudgetID` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `categories`
--
ALTER TABLE `categories`
  MODIFY `CategoryID` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT for table `expenses`
--
ALTER TABLE `expenses`
  MODIFY `ExpenseID` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `income`
--
ALTER TABLE `income`
  MODIFY `IncomeID` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT for table `messages`
--
ALTER TABLE `messages`
  MODIFY `MessageID` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `notifications`
--
ALTER TABLE `notifications`
  MODIFY `NotificationID` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `reports`
--
ALTER TABLE `reports`
  MODIFY `ReportID` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `users`
--
ALTER TABLE `users`
  MODIFY `UserID` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `budgets`
--
ALTER TABLE `budgets`
  ADD CONSTRAINT `budgets_ibfk_1` FOREIGN KEY (`UserID`) REFERENCES `users` (`UserID`) ON DELETE CASCADE,
  ADD CONSTRAINT `budgets_ibfk_2` FOREIGN KEY (`CategoryID`) REFERENCES `categories` (`CategoryID`) ON DELETE CASCADE;

--
-- Constraints for table `categories`
--
ALTER TABLE `categories`
  ADD CONSTRAINT `categories_ibfk_1` FOREIGN KEY (`CategoryType`) REFERENCES `categorytypes` (`CategoryType`);

--
-- Constraints for table `expenses`
--
ALTER TABLE `expenses`
  ADD CONSTRAINT `expenses_ibfk_1` FOREIGN KEY (`UserID`) REFERENCES `users` (`UserID`) ON DELETE CASCADE,
  ADD CONSTRAINT `expenses_ibfk_2` FOREIGN KEY (`CategoryID`) REFERENCES `categories` (`CategoryID`);

--
-- Constraints for table `income`
--
ALTER TABLE `income`
  ADD CONSTRAINT `income_ibfk_1` FOREIGN KEY (`UserID`) REFERENCES `users` (`UserID`) ON DELETE CASCADE,
  ADD CONSTRAINT `income_ibfk_2` FOREIGN KEY (`CategoryID`) REFERENCES `categories` (`CategoryID`);

--
-- Constraints for table `messages`
--
ALTER TABLE `messages`
  ADD CONSTRAINT `messages_ibfk_1` FOREIGN KEY (`SenderID`) REFERENCES `users` (`UserID`) ON DELETE CASCADE,
  ADD CONSTRAINT `messages_ibfk_2` FOREIGN KEY (`ReceiverID`) REFERENCES `users` (`UserID`) ON DELETE CASCADE;

--
-- Constraints for table `notifications`
--
ALTER TABLE `notifications`
  ADD CONSTRAINT `notifications_ibfk_1` FOREIGN KEY (`UserID`) REFERENCES `users` (`UserID`),
  ADD CONSTRAINT `notifications_ibfk_2` FOREIGN KEY (`SenderID`) REFERENCES `users` (`UserID`);

--
-- Constraints for table `reports`
--
ALTER TABLE `reports`
  ADD CONSTRAINT `reports_ibfk_1` FOREIGN KEY (`UserID`) REFERENCES `users` (`UserID`) ON DELETE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
