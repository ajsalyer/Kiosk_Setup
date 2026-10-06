unsigned pinout[] = {2,3,4,5,6,7,8,9,10,11,12};  // digital pins assigned to the channels
const unsigned nchan = sizeof(pinout) / sizeof(unsigned);  // number of reward channels

// Safety limits for one 'Y' command. A malformed or corrupted command must
// not be able to hold a solenoid open: anything outside these limits is
// rejected with P3 and nothing is delivered. mGLO's pulses are ~100 ms.
const long MAX_DURATION_MS = 2000;  // one pulse
const long MAX_NUM_REWARD  = 50;    // pulses per command
const long MAX_PAUSE_MS    = 5000;  // gap between pulses

// True if s is a non-negative decimal number: digits with at most one '.'
// (String::toInt() silently returns 0 for text, which used to make
// "Yx,y,z,w" reply OK and deliver nothing).
bool isUnsignedNumber(const String &s)
{
  bool digit = false, point = false;
  for (unsigned int i=0; i<s.length(); i++)
  {
    char c = s.charAt(i);
    if (isDigit(c)) digit = true;
    else if ('.'==c && !point) point = true;
    else return false;
  }
  return digit;
}

// Parse a string accepted by isUnsignedNumber, rounded to the nearest whole
// number (durations may arrive as e.g. "80.0").
long toRoundedLong(const String &s)
{
  return (long)(s.toFloat() + 0.5);
}

void setup()
{
  for (size_t m=0; m<nchan; m++)
  {
    pinMode(pinout[m], OUTPUT);
    digitalWrite(pinout[m], LOW);
  }
  pinMode(LED_BUILTIN, OUTPUT);  // D13
  digitalWrite(LED_BUILTIN, LOW);

  Serial.begin(38400);
}

void loop()
{
  if (Serial)
  {
    String cmd = Serial.readStringUntil('\n');
    cmd.trim();
    if (0==cmd.length()) return;

    String result = "P1";  // Command not understood
    switch (cmd.charAt(0))
    {

      case 'Q':  // query current state
        result = "READY";
        break;
      
      case 'R':  // reset
        result = "OK";
        break;

      case 'Y':
      {  // deliver reward, Y<juice line>,<duration>,<num reward>,<pause time>
        long comma1 = cmd.indexOf(',',1);
        long comma2 = cmd.indexOf(',',comma1+1);
        long comma3 = cmd.indexOf(',',comma2+1);
        if (comma1<1 || comma2<1 || comma3<1)
        {
          result = "P3";  // Parameter error
          break;
        }

        String sLine  = cmd.substring(1,comma1);
        String sDur   = cmd.substring(comma1+1,comma2);
        String sNum   = cmd.substring(comma2+1,comma3);
        String sPause = cmd.substring(comma3+1);
        sLine.trim(); sDur.trim(); sNum.trim(); sPause.trim();
        if (!isUnsignedNumber(sLine) || !isUnsignedNumber(sDur) ||
            !isUnsignedNumber(sNum)  || !isUnsignedNumber(sPause))
        {
          result = "P3";  // Parameter error: not a number
          break;
        }

        long line1     = toRoundedLong(sLine);   // 1-based as sent
        long duration  = toRoundedLong(sDur);
        long numreward = toRoundedLong(sNum);
        long pausetime = toRoundedLong(sPause);
        if (line1<1 || (long)nchan<line1)
        {
          result = "P2";  // Solenoid does not exist
          break;
        }
        if (duration<1 || MAX_DURATION_MS<duration ||
            numreward<1 || MAX_NUM_REWARD<numreward ||
            MAX_PAUSE_MS<pausetime)
        {
          result = "P3";  // Parameter error: out of the safe range
          break;
        }
        unsigned long juiceline = line1 - 1;  // 0-based

        for (long m=1; m<=numreward; m++)
        {
          digitalWrite(LED_BUILTIN, HIGH);
          digitalWrite(pinout[juiceline], HIGH);
          delay(duration);
          digitalWrite(pinout[juiceline], LOW);
          digitalWrite(LED_BUILTIN, LOW);
          if (m<numreward) delay(pausetime);
        }
        result = "OK";
        break;
      }
    }
    
    Serial.write((result + '\n').c_str());
  }
}
