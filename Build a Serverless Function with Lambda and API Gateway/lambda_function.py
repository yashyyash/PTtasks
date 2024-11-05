def lambda_handler(event, context):
    # HTML content with inline CSS for simple styling
    html_content = """
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <title>Hello from Lambda</title>
        <style>
            body {
                font-family: Arial, sans-serif;
                background-color: #f0f0f5;
                color: #333;
                text-align: center;
                padding-top: 50px;
            }
            .container {
                display: inline-block;
                padding: 20px;
                border: 2px solid #4CAF50;
                border-radius: 10px;
                background-color: pink;
            }
            h1 {
                color: #4CAF50;
            }
        </style>
    </head>
    <body>
        <div class="container">
            <h1>Hello World,This is me Yash Mutatkar!</h1>
            <p>This is my first serverless function with HTML response!</p>
        </div>
    </body>
    </html>
    """
    
    return {
        'statusCode': 200,
        'headers': {
            'Content-Type': 'text/html'
        },
        'body': html_content
    }
