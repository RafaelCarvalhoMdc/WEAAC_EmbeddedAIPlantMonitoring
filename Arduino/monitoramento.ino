#include "DHT.h"
#include <Javino.h>

// Configurações do DHT11 (Temperatura e Umidade do Ar)
#define DHTPIN A1       
#define DHTTYPE DHT11   
DHT dht(DHTPIN, DHTTYPE);

// Inicializa o Javino
Javino javino;

void setup() {
  // O ChonIDE geralmente usa 9600 ou 115200. Vamos manter 9600 como no seu original.      
  
  // Pino do sensor de luz (Digital)
  pinMode(2, INPUT);       
  
  // Inicializa o sensor DHT
  dht.begin();

  javino.perceive(percebe);
  javino.start(9600);
}
void loop(){
  javino.run();
}

void serialEvent(){javino.readSerial();}

void percebe() {
  // --- 1. LEITURA DOS SENSORES ---

  // Umidade do Solo (Analógico no A0)
  int umidadeBruta = analogRead(A0);
  int umidadeSolo = map(umidadeBruta, 1023, 375, 0, 100);
  umidadeSolo = constrain(umidadeSolo, 0, 100);
  
  // Temperatura do Ar (DHT11 no A1)
  float tempAr = dht.readTemperature();
  
  // Luz (Digital no D2)
  int luz = digitalRead(2);

  // --- 2. FORMATAÇÃO PARA O CHONIDE ---
  
  // Criamos a String no formato que o Agente Jason entende.
  // Importante: cada percepção termina com ponto e vírgula (;), exceto a última.


  // --- 3. ENVIO DOS DADOS ---
  
  // O comando javino.send empacota a String e envia via Serial
  //javino.sendMsg(percepcoes);
  javino.addPercept("umidadeSolo(" + String(umidadeSolo) + ")");
  javino.addPercept("temperatura(" + String(tempAr) + ")");
  javino.addPercept("luz(" + String(luz) + ")");

  // No ChonIDE, não precisamos de um delay tão longo. 
  // 2 segundos (2000ms) é um tempo ótimo para os agentes reagirem. 
}