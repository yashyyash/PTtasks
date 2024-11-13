<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Hello World - Yash Mutatkar's App</title>
    <style>
        /* Basic inline CSS for styling sections */
        body {
            font-family: Arial, sans-serif;
            margin: 0;
            padding: 0;
            text-align: center;
            background-color: #f0f0f5;
        }
        h1 {
            color: #333;
        }
        section {
            padding: 20px;
            border: 1px solid #ccc;
            margin: 10px;
            background-color: #fff;
            border-radius: 8px;
            width: 80%;
            margin: auto;
        }
        .calc-section, .game-section, .thankyou-section {
            margin-top: 20px;
        }
        input, button {
            padding: 10px;
            margin: 5px;
            border: 1px solid #999;
            border-radius: 5px;
        }
    </style>
</head>
<body>

    <h1>Hello World - This is Yash Mutatkar's App</h1>

    <!-- Section 1: Basic Calculator -->
    <section class="calc-section">
        <h2>Basic Calculator</h2>
        <form method="post">
            <input type="number" name="num1" placeholder="Enter first number" required>
            <input type="number" name="num2" placeholder="Enter second number" required>
            <select name="operation">
                <option value="add">Add</option>
                <option value="subtract">Subtract</option>
                <option value="multiply">Multiply</option>
                <option value="divide">Divide</option>
            </select>
            <button type="submit" name="calculate">Calculate</button>
        </form>
        <?php
            if (isset($_POST['calculate'])) {
                $num1 = $_POST['num1'];
                $num2 = $_POST['num2'];
                $operation = $_POST['operation'];
                $result = 0;

                // Perform basic calculation based on the selected operation
                if ($operation == "add") {
                    $result = $num1 + $num2;
                } elseif ($operation == "subtract") {
                    $result = $num1 - $num2;
                } elseif ($operation == "multiply") {
                    $result = $num1 * $num2;
                } elseif ($operation == "divide") {
                    $result = $num2 != 0 ? $num1 / $num2 : "Cannot divide by zero";
                }

                echo "<p>Result: $result</p>";
            }
        ?>
    </section>

    <!-- Section 2: Basic Game (Guess the Number) -->
    <section class="game-section">
        <h2>Guess the Number Game</h2>
        <p>Guess a number between 1 and 10:</p>
        <form method="post">
            <input type="number" name="guess" min="1" max="10" placeholder="Your guess" required>
            <button type="submit" name="play">Guess</button>
        </form>
        <?php
            if (isset($_POST['play'])) {
                $guess = $_POST['guess'];
                $randomNumber = rand(1, 10);

                // Display result based on guess comparison with random number
                if ($guess == $randomNumber) {
                    echo "<p>Congratulations! You guessed it right! The number was $randomNumber.</p>";
                } else {
                    echo "<p>Try again! The correct number was $randomNumber.</p>";
                }
            }
        ?>
    </section>

    <!-- Section 3: Thank You Section -->
    <section class="thankyou-section">
        <h2>Thank You</h2>
        <p>Thank you for using Yash Mutatkar's app. Hope you enjoyed it!</p>
    </section>

</body>
</html>
