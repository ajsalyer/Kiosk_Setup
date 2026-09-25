unsigned pinout[] = {2,3,4,5,6,7,8,9,10,11,12};  // digital pins assigned to the channels
const unsigned nchan = sizeof(pinout) / sizeof(unsigned);  // number of reward channels

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
        if (comma1<1 || comma2<1 | comma3<1)
        {
          result = "P3";  // Parameter error
          break;
        }

        unsigned long juiceline = cmd.substring(1,comma1).toInt() - 1;  // 0-based
        unsigned long duration = cmd.substring(comma1+1,comma2).toInt();
        unsigned long numreward = cmd.substring(comma2+1,comma3).toInt();
        unsigned long pausetime = cmd.substring(comma3+1).toInt();
        if (nchan<=juiceline)
        {
          result = "P2";  // Solenoid does not exist
          break;
        }

        for (size_t m=1; m<=numreward; m++)
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
