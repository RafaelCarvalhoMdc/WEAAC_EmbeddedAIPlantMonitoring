emailUSER("dono@gmail.com"). //incluir email real para o qual as mensagens deverão ser enviadas

!start.

+!start<-
	.mailer.credentials("SEU_EMAIL","SUA_SENHA");
	.mailer.eMailService(["imap.gmail.com",imaps],["smtp.gmail.com",smtpOverTLS]);
	.print("Email Configurado");

	?emailUSER(USER);
	.mailer.sendEMail(USER, tell, "Oi, to funcionando em parte");
	.print("Agente de email iniciado.").
	

+teste<-
	.print("Recebi uma mensagem do agente da planta!").

+relatorio( Sol, HorasNec, Frio, Confortavel, Quente, Seco, Ideal, Encharcado )<-
	SolHoras = Sol / 60;
	SolNec = HorasNec;
	TempoFrio = Frio * 5;
	TempoConfortavel = Confortavel * 5;
	TempoQuente = Quente * 5;
	TempoSeco = Seco * 5;
	TempoIdeal = Ideal * 5;
	TempoEncharcado = Encharcado * 5;

	.print("===== RELATORIO DIARIO =====");
	.print("Tempo de sol: ", SolHoras, " horas");
	.print("Tempo de sol necessário: ", SolNec, " horas");
	.print("Tempo frio: ", TempoFrio, " minutos");
	.print("Tempo confortavel: ", TempoConfortavel, " minutos");
	.print("Tempo quente: ", TempoQuente, " minutos");
	.print("=== UMIDADE DO SOLO ===");
	.print("Tempo seco: ", TempoSeco, " minutos");
	.print("Tempo ideal: ", TempoIdeal, " minutos");
	.print("Tempo encharcado: ", TempoEncharcado, " minutos");

	.concat("Relatório Diario                                                           Tempo de sol: ", SolHoras , " de ", SolNec, " horas necessárias.                         Tempo de clima frio: " , TempoFrio, " min.                                             Tempo de clima quente: " , TempoQuente, " min.                                   Tempo de clima confortavel: " , TempoConfortavel, " min.                               Tempo com solo seco: " , TempoSeco, " min.                                   Tempo com solo encharcado: " , TempoEncharcado, " min.                                 Tempo com umidade do solo ideal: " , TempoIdeal, " min.", MensagemRelatorio);
	?emailUSER(USER);
	.mailer.sendEMail(USER,tell, MensagemRelatorio).

+alerta_seco(T)<-
   	TempoMin = T * 5;
 	Horas = TempoMin / 60;

   	.print("===== ALERTA =====");
   	.print("SOLO SECO");
   	.print("Tempo acumulado: ", Horas, " horas");
   	.print("Ação recomendada: irrigação imediata.");
	.concat("Alerta: Solo Seco! Tempo: ", Horas, " horas. Irrigar.", MSG);
	?emailUSER(USER);
	.mailer.sendEMail(USER,tell, MSG).



+alerta_encharcado(T)<-
   	TempoMin = T * 5;
   	Horas = TempoMin / 60;

   	.print("===== ALERTA =====");
   	.print("SOLO ENCHARCADO");
   	.print("Tempo acumulado: ", Horas, " horas");
   	.print("Ação recomendada: verificar drenagem e suspender irrigação.");
	?emailUSER(USER);
	.mailer.sendEMail(USER,tell, "Alerta: Solo Encharcado! Tempo: ", Horas, "horas. Irrigar.").

