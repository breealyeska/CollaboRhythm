<?xml version='1.0' encoding='ISO-8859-1'?>
<xsl:stylesheet version = '1.0' xmlns:xsl='http://www.w3.org/1999/XSL/Transform' xmlns:indivodoc="http://indivo.org/vocab/xml/documents#"> 
  <xsl:output method = "xml" indent = "yes" />  
  <xsl:template match="indivodoc:Procedure">
    <Models>
      <Model name="Procedure">
        <Field name="date_performed"><xsl:value-of select='indivodoc:datePerformed/text()' /></Field>
        <xsl:if test="indivodoc:name">
	  <Field name="name"><xsl:value-of select='indivodoc:name/text()' /></Field>
	  <Field name="name_type"><xsl:value-of select='indivodoc:name/@type' /></Field>
	  <Field name="name_value"><xsl:value-of select='indivodoc:name/@value' /></Field>
	  <Field name="name_abbrev"><xsl:value-of select='indivodoc:name/@abbrev' /></Field>
        </xsl:if>
        <xsl:apply-templates select='indivodoc:provider' />
        <Field name="location"><xsl:value-of select='indivodoc:location/text()' /></Field>
        <Field name="comments"><xsl:value-of select='indivodoc:comments/text()' /></Field>
      </Model>
    </Models>
  </xsl:template>
  <xsl:template match="indivodoc:provider">
    <xsl:if test="indivodoc:name">
      <Field name="provider_name"><xsl:value-of select='indivodoc:name/text()' /></Field>
    </xsl:if>
    <xsl:if test="indivodoc:institution">
      <Field name="provider_institution"><xsl:value-of select='indivodoc:institution/text()' /></Field>
    </xsl:if>
  </xsl:template>
</xsl:stylesheet>
