<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:exsl="http://exslt.org/common" extension-element-prefixes="exsl">
	<xsl:output method="xml" indent="yes"/>
	<xsl:param name="application_name"/>
	
	<xsl:template match="/">
		<!-- Title page -->
		<exsl:document href="index.html" method="html">
			<html>
				<head>
					<title><xsl:value-of select="name"/><xsl:value-of select="$application_name"/><xsl:text> guide</xsl:text></title>
					<meta name="AppleTitle" content="{$application_name} Help"/>
					<meta name="AppleIcon" content="Help/{$application_name}16.png"/>
					<link rel="stylesheet" href="helpbook.css" type="text/css"/>
					</head>
				<body>
					<h1><xsl:value-of select="$application_name"/> guide</h1>
					<p>
					<span style="color: orange">NOTE:</span> this help book has not been updated for Version 2 of Geotagalog yet.
					Please contact <a href="http://calftrail.com/support.html">support@calftrail.com</a> for personal assistance.
					</p>
					<ul>
						<xsl:for-each select="helpbook/link">
							<li>
								<xsl:apply-templates select="."><xsl:with-param name="main_page" select="true()"/></xsl:apply-templates><br/>
								<!-- See note in link template for use of variable -->
								<xsl:variable name="requested_page_id" select="@href"/>
								<xsl:value-of select="/helpbook/page[@id=$requested_page_id]/summary"/>
								</li>
							</xsl:for-each>
						</ul>
					</body>
				</html>
			</exsl:document>
		
		<!-- Generate pages -->
		<xsl:apply-templates select="helpbook/page"/>
		</xsl:template>
	
	<xsl:template match="page">
		<exsl:document href="pages/{@id}.html" method="html">
			<html>
				<head>
					<title><xsl:value-of select="$application_name"/> guide — <xsl:value-of select="name"/></title>
					<link rel="stylesheet" href="../helpbook.css" type="text/css"/>
					</head>
				<body>
					<h2><xsl:value-of select="name"/></h2>
					<xsl:apply-templates select="content"/>
					</body>
				</html>
			</exsl:document>
		</xsl:template>
	
	<xsl:template match="link">
		<xsl:param name="main_page"/>
		<xsl:variable name="page_url">
			<xsl:choose>
				<xsl:when test="$main_page">
					<xsl:text>pages/</xsl:text><xsl:value-of select="@href"/><xsl:text>.html</xsl:text>
					</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="@href"/><xsl:text>.html</xsl:text>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:variable>
		<a href="{$page_url}">
			<xsl:choose>
				<xsl:when test="text()"><xsl:value-of select="text()"/></xsl:when>
				<xsl:otherwise>
					<!-- couln't figure out how to query @id='{@href}' directly without variable -->
					<xsl:variable name="requested_page_id" select="@href"/>
					<xsl:value-of select="/helpbook/page[@id=$requested_page_id]/name"/>
					</xsl:otherwise>
				</xsl:choose>
			</a>
		</xsl:template>
	
	<!-- deep copy elements with HTML bodies -->
	<xsl:template match="*">
		<xsl:element name="{name()}">
			<xsl:apply-templates select="@*|*|text()"/>
			</xsl:element>
	 	</xsl:template>
	<xsl:template match="@*">
		<xsl:attribute name="{name()}">
			<xsl:value-of select="."/>
			</xsl:attribute>
		</xsl:template>
	<xsl:template match="text()">
		<xsl:copy>
			<xsl:apply-templates select="node()"/>
			</xsl:copy>
		</xsl:template>
	
	</xsl:stylesheet>