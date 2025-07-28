#!/bin/bash

# Presentation Generator Script
echo "Generating workshop presentations..."

# Check if pandoc is available
if ! command -v pandoc &> /dev/null; then
    echo "Warning: pandoc not found. Install pandoc to generate PDF/HTML presentations."
    echo "Ubuntu/Debian: sudo apt install pandoc"
    echo "macOS: brew install pandoc"
    echo "Windows: Download from https://pandoc.org/installing.html"
fi

# Create presentations directory if it doesn't exist
mkdir -p presentations/output

# Convert markdown presentations to various formats
echo "Converting presentations..."

# Generate HTML slides (reveal.js)
if command -v pandoc &> /dev/null; then
    echo "Generating HTML presentation..."
    pandoc presentations/workshop-overview.md \
        -o presentations/output/workshop-overview.html \
        -t revealjs \
        -s \
        --slide-level=2 \
        --theme=beige \
        --transition=slide \
        --highlight-style=github \
        --variable revealjs-url=https://unpkg.com/reveal.js@4.3.1/

    # Generate PDF presentation
    echo "Generating PDF presentation..."
    pandoc presentations/workshop-overview.md \
        -o presentations/output/workshop-overview.pdf \
        -t beamer \
        --slide-level=2 \
        --theme=Madrid \
        --colortheme=default

    # Generate PPTX presentation  
    echo "Generating PowerPoint presentation..."
    pandoc presentations/workshop-overview.md \
        -o presentations/output/workshop-overview.pptx \
        --slide-level=2

    echo "✅ Presentations generated in presentations/output/"
else
    echo "⚠️ Pandoc not available. Presentations remain in markdown format."
fi

# Create presentation index
cat > presentations/output/index.html << 'INDEX_END'
<!DOCTYPE html>
<html>
<head>
    <title>GCP Landing Zone Workshop Presentations</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; }
        .presentation { margin: 20px 0; padding: 20px; border: 1px solid #ddd; border-radius: 5px; }
        .download-links a { margin-right: 15px; text-decoration: none; color: #0066cc; }
        .download-links a:hover { text-decoration: underline; }
    </style>
</head>
<body>
    <h1>GCP Landing Zone Workshop Presentations</h1>
    
    <div class="presentation">
        <h2>Workshop Overview</h2>
        <p>Main presentation covering workshop objectives, structure, and learning outcomes.</p>
        <div class="download-links">
            <a href="workshop-overview.html">HTML Slides</a>
            <a href="workshop-overview.pdf">PDF</a>
            <a href="workshop-overview.pptx">PowerPoint</a>
        </div>
    </div>
    
    <div class="presentation">
        <h2>Architecture Diagrams</h2>
        <p>Comprehensive architecture documentation and diagrams.</p>
        <div class="download-links">
            <a href="../diagrams/architecture-overview.md">Architecture Guide</a>
        </div>
    </div>
    
    <div class="presentation">
        <h2>Concept Guides</h2>
        <p>Detailed conceptual explanations for each lab.</p>
        <div class="download-links">
            <a href="../guides/lab-01-concepts.md">Lab 01 Concepts</a>
            <a href="../guides/lab-02-concepts.md">Lab 02 Concepts</a>
        </div>
    </div>
    
    <p><em>Generated on: $(date)</em></p>
</body>
</html>
INDEX_END

echo "✅ Presentation index created: presentations/output/index.html"
