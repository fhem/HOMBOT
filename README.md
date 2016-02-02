<h3>HOMBOT</h3>
<ul>
  <u><b>HOMBOT - LG Homebot Staubsaugerroboter</b></u>
  <br>
  Dieses Modul gibt Euch die Möglichkeit Euren Hombot nach erfolgreichen Hack in FHEM ein zu binden.
  Voraussetzung ist das Ihr den Hombot Hack gemacht und einen WLAN Stick eingebaut habt. Als Schnittstelle zwischen FHEM und Bot wird der Luigi HTTP Server verwendet. Was genau könnt Ihr nun mit dem Modul machen:
  <ul>
    <li>Readings über den Status des Hombots werden angelegt</li>
    <li>Auswahl des Reinigungsmodus ist möglich</li>
    <li>Starten der Reinigung</li>
    <li>Beenden der Reinigung</li>
    <li>zurück zur Homebase schicken</li>
    <li>Namen vergeben</li>
    <li>Wochenprogramm einstellen</li>
    <li>Repeat und Turbo aktivieren</li>
  </ul>
  
  <br>
  Das Device für den Hombot legt Ihr wie folgt in FHEM an.
  <br><br>
  <a name="HOMBOTdefine"></a>
  <b>Define</b>
  <ul><br>
    <code>define &lt;name&gt; HOMBOT &lt;IP-ADRESSE&gt;</code>
    <br><br>
    Beispiel:
    <ul><br>
      <code>define Roberta HOMBOT 192.168.0.23</code><br>
    </ul>
    <br>
    Diese Anweisung erstellt ein neues HOMBOT-Device im Raum HOMBOT.Der Parameter &lt;IP-ADRESSE&gt; legt die IP Adresse des LG Hombot fest.<br>
    Das Standard Abfrageinterval ist 180 Sekunden und kann &uuml;ber das Attribut intervall ge&auml;ndert werden. Das Interval ist in Abhängigkeit des Arbeitsstatus dynamisch. Im Status WORKING beträgt es z.B. 30 Sekunden.
    <br>
  </ul>
  <br><br> 
  <b><u>Nach anlegen der Ger&auml;teinstanz sollten bereits die ersten Readings erscheinen.</u></b>
  <br><br><br>
  <a name="HOMBOTreadings"></a>
  <b>Readings</b>
  <ul>
    <li>at_* - Reading für das Wochenprogramm. Startzeit für den jeweiligen Tag</li>
    <li>batteryPercent - Status der Batterie in %</li>
    <li>cleanMode - aktuell eingestellter Reinigungsmodus</li>
    <li>cpu_* - Informationen über die Prozessorauslastung</li>
    <li>currentBumping - Anzahl der Zusammenst&ouml;&szlig;e mit Hindernissen</li>
    <li>firmware - aktuell installierte Firmwareversion</li>
    <li>hombotState - Status des Hombots</li>
    <li>lastClean - Datum und Uhrzeit der letzten Reinigung</li>
    <li>lastSetCommandError - letzte Fehlermeldung vom set Befehl</li>
    <li>lastSetCommandState - letzter Status vom set Befehl, Befehl erfolgreich/nicht erfolgreich gesendet</li>
    <li>lastStatusRequestError - letzte Fehlermeldung vom statusRequest Befehl</li>
    <li>lastStatusRequestState - letzter Status vom statusRequest Befehl, Befehl erfolgreich/nicht erfolgreich gesendet</li>
    <li>luigiSrvVersion - Version des Luigi HTTP Servers auf dem Hombot</li>
    <li>nickname - Name des Hombot</li>
    <li>num* - Bisher begonnene und beendete Reinigungen im entsprechenden Modus</li>
    <li>repeat - Reinigung wird wiederholt Ja/Nein</li>
    <li>state - Modulstatus</li>
    <li>turbo - Turbo aktiv Ja/Nein</li>
  </ul>
  <br><br>
  <a name="HOMBOTset"></a>
  <b>Set</b>
  <ul>
    <li>cleanMode - setzen des Reinigungsmodus (ZZ-ZickZack / SB-Cell by Cell / SPOT-Spiralreinigung</li>
    <li>cleanStart - Reinigung starten</li>
    <li>homing - Beendet die Reinigung und l&auml;sst die Bot zur&uuml;ck zur Bases kommen</li>
    <li>nickname - setzt des Bot-Namens. Wird im Reading erst nach einem neustart des Luigiservers oder des Bots sichtbar</li>
    <li>pause - lässt den Reinigungspro&szlig;ess pausieren</li>
    <li>repeat - Reinigung wiederholen? (true/false)</li>
    <li>schedule - setzen des Wochenprogrammes Bsp. set Roberta schedule Mo=13:30 Di= Mi=14:00,ZZ Do=15:20 Fr= Sa=11:20 So=  Man kann also auch den Modus mitgeben!</li>
    <li>statusRequest - Fordert einen neuen Statusreport beim Device an</li>
    <li>turbo - aktivieren des Turbomodus (true/false)</li>
  </ul>
  <br><br>
</ul>