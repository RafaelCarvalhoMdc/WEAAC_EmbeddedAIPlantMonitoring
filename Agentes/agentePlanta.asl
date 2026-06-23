## Agente Planta (`agentePlanta.asl`)

O código abaixo foi desenvolvido em **AgentSpeak**, linguagem utilizada pelo framework Jason para Sistemas Multiagentes.

// ==========================================
// 1ª ETAPA: CONFIGURAÇÃO DO HARDWARE (ARGO)
// ==========================================

serialPort(ttyUSB0).

// Controle do relatório diário
ciclos_relatorio(0).

// Histórico diário da umidade
historico_seco(0).
historico_ideal(0).
historico_encharcado(0).

// Constante de calibração do projeto
horas_sol_necessarias(4).

// Histórico de temperatura
tempo_frio(0).
tempo_confortavel(0).
tempo_quente(0).

// variáveis de umidade para alertas
tempo_seco(0).
tempo_encharcado(0).
alerta_seco_enviado(false).
alerta_encharcado_enviado(false).

+!teste_email
   <-
      .print("Enviando mensagem para agenteEmail...");
      .send(
         agenteEmail,
         tell,
         gerar_relatorio
      ).


// ==========================================
// 2ª ETAPA: REGRAS DE INFERÊNCIA (CRENÇAS)
// ==========================================

// Classifica o estado do solo com base na leitura do Arduino
solo(seco) :- umidadeSolo(U) & U < 20.
solo(ideal) :- umidadeSolo(U) & U >= 20 & U <= 60.
solo(encharcado) :- umidadeSolo(U) & U > 60.

// Classifica o clima com base no sensor DHT11
clima(frio) :- temperatura(T) & T < 15.
clima(confortavel) :- temperatura(T) & T >= 15 & T <= 30.
clima(quente) :- temperatura(T) & T > 30.

// Avalia o histórico de luminosidade acumulada
historico_luz(suficiente) :- minutos_sol_acumulados(M) & horas_sol_necessarias(H) & M >= (H * 60).
historico_luz(insuficiente) :- minutos_sol_acumulados(M) & horas_sol_necessarias(H) & M < (H * 60).

// Inicializa o contador de sol zerado
minutos_sol_acumulados(0).


// ==========================================
// 3ª ETAPA: INICIALIZAÇÃO DO AGENTE
// ==========================================

!start.

+!start : serialPort(Port) <-
   .print("Iniciando conexao com a planta na porta: ", Port);
   .argo.port(Port);
   .argo.percepts(open);
   .argo.limit(3000); // Timeout de 3 segundos
   .print("Aguardando resposta dos sensores do Arduino...");
   !loop;
   !teste_email.

-!start <-
   .print("Falha critica ao iniciar o barramento serial.").


// ==========================================
// 4ª ETAPA: REAÇÃO ÀS PERCEPÇÕES DO JAVINO
// ==========================================

+luz(L) <-
   // Executa o plano para computar o tempo de sol
   !computar_tempo_luz(L).

// PLANO: Se o sensor de luz ler 0 (Dependendo do sensor, 0 é "com luz" ou "escuro".
// Ajuste o valor abaixo se o seu sensor funcionar com lógica invertida!)

+!computar_tempo_luz(0) <-
   ?minutos_sol_acumulados(TempoAtual);
   NovaContagem = TempoAtual + 0.1;

   // Incrementa a aproximação do tempo de amostragem
   -minutos_sol_acumulados(TempoAtual);
   +minutos_sol_acumulados(NovaContagem);

   .print("Planta detectada no SOL. Acumulado: ", NovaContagem, " minutos.").

+!computar_tempo_luz(1) <-
   ?minutos_sol_acumulados(TempoAtual);
   .print("Planta detectada na SOMBRA. Tempo congelado em: ", TempoAtual, " minutos.").


+!loop <-
   !ler_sensores;
   .wait(3000); // intervalo de x minutos (mudar depois para 5 min)
   !loop.

+!ler_sensores <-
   .print("=== CICLO DE LEITURA ===");
   ?umidadeSolo(U);
   ?temperatura(T);

   .print("Umidade: ", U);
   .print("Temperatura: ", T);

   !avaliar_condicoes;
   !atualizar_ciclos_relatorio;
   !verificar_relatorio.

+!avaliar_condicoes <-
   !classificar_solo;
   !classificar_clima;
   !monitorar_umidade;
   !atualizar_historico_temperatura.

+!atualizar_historico_temperatura : clima(frio) <-
   ?tempo_frio(T);
   Novo = T + 1;
   -tempo_frio(T);
   +tempo_frio(Novo);

   .print("Tempo frio acumulado: ", Novo).

+!atualizar_historico_temperatura : clima(confortavel) <-
   ?tempo_confortavel(T);
   Novo = T + 1;
   -tempo_confortavel(T);
   +tempo_confortavel(Novo);

   .print("Tempo confortável acumulado: ", Novo).

+!atualizar_historico_temperatura : clima(quente) <-
   ?tempo_quente(T);
   Novo = T + 1;
   -tempo_quente(T);
   +tempo_quente(Novo);

   .print("Tempo quente acumulado: ", Novo).

+!classificar_solo <-
   ?solo(S);
   .print("Estado do solo: ", S).

+!classificar_clima <-
   ?clima(C);
   .print("Estado do clima: ", C).

+!monitorar_umidade : solo(seco) <-
   ?tempo_seco(T);
   Novo = T + 1;
   -tempo_seco(T);
   +tempo_seco(Novo);

   ?historico_seco(H);
   NovoHist = H + 1;
   -historico_seco(H);
   +historico_seco(NovoHist);

   .print("Contador solo seco acumulado: ", Novo);
   .print("Contador solo seco diário: ", NovoHist);

   !verificar_alerta_seco.

+!monitorar_umidade : solo(encharcado) <-
   ?tempo_encharcado(T);
   Novo = T + 1;
   -tempo_encharcado(T);
   +tempo_encharcado(Novo);

   ?historico_encharcado(H);
   NovoHist = H + 1;
   -historico_encharcado(H);
   +historico_encharcado(NovoHist);

   .print("Contador solo encharcado acumulado: ", Novo);
   .print("Contador solo encharcado diário: ", NovoHist);

   !verificar_alerta_encharcado.

+!monitorar_umidade : solo(ideal) <-
   ?historico_ideal(H);
   NovoHist = H + 1;
   -historico_ideal(H);
   +historico_ideal(NovoHist);

   .print("Solo voltou ao estado ideal. Zerando contadores.");

   -tempo_seco(_);
   +tempo_seco(0);

   -tempo_encharcado(_);
   +tempo_encharcado(0);

   -alerta_seco_enviado(_);
   +alerta_seco_enviado(false);

   -alerta_encharcado_enviado(_);
   +alerta_encharcado_enviado(false).

+!verificar_alerta_seco
   : tempo_seco(T) &
     alerta_seco_enviado(false) &
     T >= 48
<-
   .print(">>> ALERTA DE SOLO SECO DISPARADO <<<");

   .send(
      agenteEmail,
      tell,
      alerta_seco(T)
   );

   -alerta_seco_enviado(false);
   +alerta_seco_enviado(true).

+!verificar_alerta_seco <- true.

+!verificar_alerta_encharcado
   : tempo_encharcado(T) &
     alerta_encharcado_enviado(false) &
     T >= 48
<-
   .print(">>> ALERTA DE SOLO ENCHARCADO DISPARADO <<<");

   .send(
      agenteEmail,
      tell,
      alerta_encharcado(T)
   );

   -alerta_encharcado_enviado(false);
   +alerta_encharcado_enviado(true).

+!verificar_alerta_encharcado <- true.

// ==========================================
// 5ª ETAPA: GERANDO RELATÓRIO DIÁRIO
// ==========================================

+!atualizar_ciclos_relatorio <-
   ?ciclos_relatorio(C);
   Novo = C + 1;
   -ciclos_relatorio(C);
   +ciclos_relatorio(Novo);

   .print("Ciclos do relatório: ", Novo).

+!verificar_relatorio : ciclos_relatorio(C) & C >= 20 <-
   .print("Hora de gerar o relatório diário.");
   !gerar_relatorio;
   -ciclos_relatorio(C);
   +ciclos_relatorio(0).

+!verificar_relatorio <- true.

+!gerar_relatorio <-
   ?minutos_sol_acumulados(Sol);
   ?tempo_frio(Frio);
   ?tempo_confortavel(Confortavel);
   ?tempo_quente(Quente);
   ?horas_sol_necessarias(HorasNec);
   ?historico_seco(Seco);
   ?historico_ideal(Ideal);
   ?historico_encharcado(Encharcado);

   .print("=== GERANDO RELATÓRIO ===");

   .send(
      agenteEmail,
      tell,
      relatorio(
         Sol,
         HorasNec,
         Frio,
         Confortavel,
         Quente,
         Seco,
         Ideal,
         Encharcado
      )
   );
 .print("RELATÓRIO ENVIADO");
   !reset_relatorio.

+!reset_relatorio <-
   -ciclos_relatorio(_);
   +ciclos_relatorio(0);

   -minutos_sol_acumulados(_);
   +minutos_sol_acumulados(0);

   -tempo_frio(_);
   +tempo_frio(0);

   -tempo_confortavel(_);
   +tempo_confortavel(0);

   -tempo_quente(_);
   +tempo_quente(0);

   .print("Reset do ciclo completo").

// ==========================================
// 6ª ETAPA: TRATAMENTO DE ERROS E RECONEXÃO
// ==========================================

+port(Port, Status) : Status = off | Status = timeout <-
   .print("Alerta: Conexao com Arduino perdida (Status: ", Status, "). Tentando reconectar...");
   .argo.percepts(close);
   .wait(1500);
   .argo.percepts(open).

