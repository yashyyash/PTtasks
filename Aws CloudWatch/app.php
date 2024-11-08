<?php
// Start session
session_start();
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>PHP App with Three Sections</title>
    <style>
        /* Basic styling */
        body {
            font-family: Arial, sans-serif;
            display: flex;
            flex-direction: column;
            align-items: center;
            margin: 20px;
        }
        .section {
            margin: 20px 0;
            padding: 20px;
            border: 1px solid #333;
            width: 400px;
            text-align: center;
        }

        /* Color wave for 'Yash Mutatakar' */
        .wave {
            animation: colorWave 7s infinite;
        }
        @keyframes colorWave {
            0% { color: violet; }
            16% { color: indigo; }
            32% { color: blue; }
            48% { color: green; }
            64% { color: yellow; }
            80% { color: orange; }
            100% { color: red; }
        }
    </style>
</head>
<body>

<!-- Section 1: Hello World with Color Wave -->
<div class="section">
    <h2>Hello World!</h2>
    <p>This is <span class="wave">Yash Mutatakar</span></p>
</div>

<!-- Section 2: Basic Calculator -->
<div class="section">
    <h2>Calculator</h2>
    <form method="post">
        <input type="number" name="num1" placeholder="Enter first number" required>
        <input type="number" name="num2" placeholder="Enter second number" required>
        <select name="operation">
            <option value="add">+</option>
            <option value="subtract">-</option>
            <option value="multiply">*</option>
            <option value="divide">/</option>
        </select>
        <button type="submit" name="calculate">Calculate</button>
    </form>
    <?php
    // Perform calculation based on selected operation
    if (isset($_POST['calculate'])) {
        $num1 = $_POST['num1'];
        $num2 = $_POST['num2'];
        $operation = $_POST['operation'];
        $result = null;

        switch ($operation) {
            case 'add':
                $result = $num1 + $num2;
                break;
            case 'subtract':
                $result = $num1 - $num2;
                break;
            case 'multiply':
                $result = $num1 * $num2;
                break;
            case 'divide':
                $result = $num2 != 0 ? $num1 / $num2 : 'Cannot divide by zero';
                break;
        }
        echo "<p>Result: $result</p>";
    }
    ?>
</div>

<!-- Section 3: Try Your Luck (Dice Roll) -->
<div class="section">
    <h2>Try Your Luck</h2>
    <form method="post">
        <label for="userNumber">Select a number (1-6):</label>
        <select name="userNumber" id="userNumber">
            <?php
            // Generate options from 1 to 6
            for ($i = 1; $i <= 6; $i++) {
                echo "<option value='$i'>$i</option>";
            }
            ?>
        </select>
        <button type="submit" name="rollDice">Roll Dice</button>
    </form>
    <?php
    // Dice roll logic
    if (isset($_POST['rollDice'])) {
        $userNumber = $_POST['userNumber'];
        $diceRoll = rand(1, 6); // Generate a random number between 1 and 6

        echo "<p>You selected: $userNumber</p>";
        echo "<p>Dice rolled: $diceRoll</p>";

        // Check if user guessed correctly
        if ($userNumber == $diceRoll) {
            echo "<p><strong>You are lucky!</strong></p>";
        } else {
            echo "<p><strong>Better luck next time!</strong></p>";
        }
    }
    ?>
</div>

</body>
</html>
