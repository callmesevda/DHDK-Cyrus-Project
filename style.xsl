<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"

    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:tei="http://www.tei-c.org/ns/1.0"
    exclude-result-prefixes="tei">

    <xsl:output method="html" encoding="UTF-8" indent="yes"/>

    <xsl:template match="/">
        <html>
            <head>
                <title>Knowledge Graph Data - Cyrus Cylinder</title>
                <style>
                    body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; margin: 40px; background-color: #f4f4f9; color: #333; }
                    h1 { text-align: center; color: #2c3e50; border-bottom: 2px solid #3498db; padding-bottom: 10px; }
                    .container { max-width: 1000px; margin: 0 auto; background: #fff; padding: 20px; box-shadow: 0 4px 8px rgba(0,0,0,0.1); border-radius: 8px; }
                    table { width: 100%; border-collapse: collapse; margin-top: 20px; }
                    th, td { border: 1px solid #ddd; padding: 12px; text-align: left; }
                    th { background-color: #3498db; color: white; font-weight: bold; }
                    tr:nth-child(even) { background-color: #f9f9f9; }
                    tr:hover { background-color: #f1f1f1; }
                    .tag { display: inline-block; padding: 4px 8px; border-radius: 4px; font-size: 0.9em; background-color: #e8f4f8; border: 1px solid #bce8f1; }
                </style>
            </head>
            <body>
                <div class="container">
                    <h1>Extracted Entities and Relationships</h1>
                    <p>This table displays the semantic relationships extracted from the TEI XML file.</p>
                    
                    <table>
                        <tr>
                            <th>Subject (Active)</th>
                            <th>Predicate (Name)</th>
                            <th>Object (Passive)</th>
                        </tr>
                        
                        <xsl:for-each select="//tei:relation">
                            <tr>
                                <td><span class="tag"><xsl:value-of select="@active"/></span></td>
                                <td><strong><xsl:value-of select="@name"/></strong></td>
                                <td><span class="tag"><xsl:value-of select="@passive"/></span></td>
                            </tr>
                        </xsl:for-each>
                    </table>
                </div>
            </body>
        </html>
    </xsl:template>

</xsl:stylesheet>