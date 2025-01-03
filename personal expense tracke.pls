-- Step 1: Create the required tables to store data for the expense tracker.

-- Table to store expense categories
CREATE TABLE Expense_Categories (
    Category_ID NUMBER PRIMARY KEY, -- Unique ID for each category
    Category_Name VARCHAR2(100) NOT NULL -- Name of the category (e.g., Food, Travel)
);

-- Table to store transactions
CREATE TABLE Transactions (
    Transaction_ID NUMBER PRIMARY KEY, -- Unique ID for each transaction
    Category_ID NUMBER NOT NULL, -- Foreign key referencing Expense_Categories
    Amount NUMBER(10, 2) NOT NULL, -- Transaction amount
    Transaction_Date DATE DEFAULT SYSDATE, -- Date of transaction
    Description VARCHAR2(255), -- Optional description of the transaction
    FOREIGN KEY (Category_ID) REFERENCES Expense_Categories(Category_ID)
);

-- Table to store budget information
CREATE TABLE Budget (
    Category_ID NUMBER PRIMARY KEY, -- Foreign key referencing Expense_Categories
    Budget_Amount NUMBER(10, 2) NOT NULL, -- Monthly budget for the category
    FOREIGN KEY (Category_ID) REFERENCES Expense_Categories(Category_ID)
);

-- Step 2: Procedure to add a new expense category
CREATE OR REPLACE PROCEDURE Add_Expense_Category(
    p_Category_Name IN VARCHAR2
) AS
BEGIN
    INSERT INTO Expense_Categories (Category_ID, Category_Name)
    VALUES (Expense_Categories_SEQ.NEXTVAL, p_Category_Name);
    DBMS_OUTPUT.PUT_LINE('Expense category added successfully.');
END;
/

-- Step 3: Procedure to add a new transaction
CREATE OR REPLACE PROCEDURE Add_Transaction(
    p_Category_ID IN NUMBER,
    p_Amount IN NUMBER,
    p_Description IN VARCHAR2
) AS
BEGIN
    INSERT INTO Transactions (Transaction_ID, Category_ID, Amount, Transaction_Date, Description)
    VALUES (Transactions_SEQ.NEXTVAL, p_Category_ID, p_Amount, SYSDATE, p_Description);
    DBMS_OUTPUT.PUT_LINE('Transaction added successfully.');
END;
/

-- Step 4: Procedure to generate a spending report by category
CREATE OR REPLACE PROCEDURE Generate_Spending_Report AS
    CURSOR Spending_Cursor IS
        SELECT EC.Category_Name, SUM(T.Amount) AS Total_Spent
        FROM Expense_Categories EC
        JOIN Transactions T ON EC.Category_ID = T.Category_ID
        GROUP BY EC.Category_Name
        ORDER BY Total_Spent DESC;
BEGIN
    DBMS_OUTPUT.PUT_LINE('Spending Report:');
    DBMS_OUTPUT.PUT_LINE('----------------------------------------');
    FOR Spending_Record IN Spending_Cursor LOOP
        DBMS_OUTPUT.PUT_LINE('Category: ' || Spending_Record.Category_Name || 
                             ', Total Spent: $' || Spending_Record.Total_Spent);
    END LOOP;
END;
/

-- Step 5: Procedure to add or update a budget for a category
CREATE OR REPLACE PROCEDURE Add_Or_Update_Budget(
    p_Category_ID IN NUMBER,
    p_Budget_Amount IN NUMBER
) AS
BEGIN
    MERGE INTO Budget B
    USING (SELECT p_Category_ID AS Category_ID FROM DUAL) D
    ON (B.Category_ID = D.Category_ID)
    WHEN MATCHED THEN
        UPDATE SET B.Budget_Amount = p_Budget_Amount
    WHEN NOT MATCHED THEN
        INSERT (Category_ID, Budget_Amount)
        VALUES (p_Category_ID, p_Budget_Amount);
    DBMS_OUTPUT.PUT_LINE('Budget updated successfully.');
END;
/

-- Step 6: Procedure to generate a budget vs. spending report
CREATE OR REPLACE PROCEDURE Generate_Budget_Report AS
    CURSOR Budget_Cursor IS
        SELECT EC.Category_Name, 
               NVL(B.Budget_Amount, 0) AS Budget_Amount,
               NVL(SUM(T.Amount), 0) AS Total_Spent
        FROM Expense_Categories EC
        LEFT JOIN Budget B ON EC.Category_ID = B.Category_ID
        LEFT JOIN Transactions T ON EC.Category_ID = T.Category_ID
        GROUP BY EC.Category_Name, B.Budget_Amount;
BEGIN
    DBMS_OUTPUT.PUT_LINE('Budget vs Spending Report:');
    DBMS_OUTPUT.PUT_LINE('----------------------------------------');
    FOR Budget_Record IN Budget_Cursor LOOP
        DBMS_OUTPUT.PUT_LINE('Category: ' || Budget_Record.Category_Name || 
                             ', Budget: $' || Budget_Record.Budget_Amount || 
                             ', Spent: $' || Budget_Record.Total_Spent);
    END LOOP;
END;
/

-- Step 7: Testing the procedures
BEGIN
    -- Add categories
    Add_Expense_Category('Food');
    Add_Expense_Category('Transport');
    Add_Expense_Category('Entertainment');
    
    -- Add transactions
    Add_Transaction(1, 50, 'Groceries');
    Add_Transaction(2, 20, 'Bus Ticket');
    Add_Transaction(1, 30, 'Dinner');
    
    -- Set budgets
    Add_Or_Update_Budget(1, 200);
    Add_Or_Update_Budget(2, 100);
    
    -- Generate reports
    Generate_Spending_Report;
    Generate_Budget_Report;
END;
/
