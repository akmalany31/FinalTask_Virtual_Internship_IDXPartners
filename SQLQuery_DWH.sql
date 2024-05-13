--Create Database
CREATE DATABASE DWH;

--Create Dimension Table & Fact Table
CREATE TABLE DimCustomer (
    CustomerID INT PRIMARY KEY,
    CustomerName VARCHAR(50),
    Address TEXT,
    CityName VARCHAR(50),
    StateName VARCHAR(50),
    Age VARCHAR(3),
    Gender VARCHAR(10),
    Email VARCHAR(50)
);
CREATE TABLE DimAccount (
    AccountID INT PRIMARY KEY,
	CustomerID INT FOREIGN KEY REFERENCES DimCustomer(CustomerID),
    AccountType VARCHAR(50),
    Balance INT,
    DateOpened DATETIME2,
    Status VARCHAR(50)
);
CREATE TABLE DimBranch (
    BranchID INT PRIMARY KEY,
    BranchName VARCHAR(50),
    BranchLocation VARCHAR(50)
);
CREATE TABLE FactTransaction (
    TransactionID INT PRIMARY KEY,
    AccountID INT FOREIGN KEY REFERENCES DimAccount(AccountID),
    CustomerID INT FOREIGN KEY REFERENCES DimCustomer(CustomerID),
    BranchID INT FOREIGN KEY REFERENCES DimBranch(BranchID),
    TransactionDate DATETIME2,
    Amount INT,
    TransactionType VARCHAR(50)
);

--Stored Procedur Daily Transaction
CREATE PROCEDURE DailyTransaction
    @start_date DATE,
    @end_date DATE
AS
BEGIN
    SELECT
        CONVERT(date, TransactionDate) AS Date,
        COUNT(*) AS TotalTransactions,
        SUM(Amount) AS TotalAmount
    FROM
        FactTransaction
    WHERE
        TransactionDate BETWEEN @start_date AND @end_date
    GROUP BY
         CONVERT(date, TransactionDate)
    ORDER BY
        CONVERT(date, TransactionDate) DESC;
END;

EXEC DailyTransaction '2024-01-01', '2024-01-31';

--Stored Procedure Balance per Customer
CREATE PROCEDURE BalancePerCustomer
    @name VARCHAR(255)
AS
BEGIN
    SELECT
        FactTransaction.TransactionID,
        DimCustomer.CustomerName,
        DimAccount.AccountType,
        DimAccount.Balance,
        DimAccount.Balance - ISNULL(SUM(
            CASE 
                WHEN FactTransaction.TransactionType = 'Deposit' THEN FactTransaction.Amount 
                ELSE -FactTransaction.Amount 
            END), 0) AS CurrentBalance
    FROM
        FactTransaction
        INNER JOIN DimAccount ON FactTransaction.AccountID = DimAccount.AccountID
        INNER JOIN DimCustomer ON DimAccount.CustomerID = DimCustomer.CustomerID
    WHERE
        DimCustomer.CustomerName = @name
        AND DimAccount.Status = 'active'
    GROUP BY
        FactTransaction.TransactionID,
        DimCustomer.CustomerName,
        DimAccount.AccountType,
        DimAccount.Balance;
END;

EXEC BalancePerCustomer 'SHELLY JUWITA';
