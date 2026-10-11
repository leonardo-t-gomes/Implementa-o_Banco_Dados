CREATE DATABASE CAIXA;
USE CAIXA;

CREATE TABLE conta(
	id INT PRIMARY KEY,
	Nome VARCHAR(50),
	Saldo MONEY
);

INSERT INTO conta
VALUES (10, 'Maria', 500),
	   (20, 'João', 1500),
	   (30, 'Paulo', 30000),
	   (40, 'Maria', 50000);
GO;

--Primeira Transaçao
BEGIN TRAN;
DECLARE @erro INT = 0;
INSERT INTO conta
VALUES (50, 'Pedro', 50);
SET @erro = @erro + @@ERROR
INSERT INTO conta
VALUES (10, 'Judas', 666);
PRINT @@ERROR
SELECT * FROM conta;
IF @erro <> 0
BEGIN 
	PRINT 'Transação Revertida;'
	ROLLBACK TRAN;
END
ELSE
BEGIN
	PRINT 'Transação Realizada com sucesso;'
	COMMIT TRAN;
-- Minha variavel erro vale 0, cada vez que acontece um erro essa variavel muda pra qualquer outro numero (se continuar em 0, significa que não encontrou erro)
END
GO;

-------------

BEGIN TRAN;
UPDATE conta
SET Saldo = saldo + 10000
WHERE Nome = 'Maria'; 
IF @@ROWCOUNT <> 1
BEGIN
	SELECT * FROM conta;
	ROLLBACK TRAN;
	SELECT * FROM conta;
END
ELSE 
	COMMIT TRAN;
GO;
-- Os selects feito dentro da transaction permite veririfcar antes de realmente comitar, ajuda a diminuir os erros reais dentro do banco
--------------

-- Transferir dinheiro de uma conta para outra


CREATE PROCEDURE usp_transferencia
	@id_conta_origem INT, --parâmetros, nome variável e tipo
	@id_conta_destino INT,
	@valor MONEY
AS
BEGIN
	BEGIN TRAN;
	UPDATE conta
	SET Saldo = Saldo - @valor
	WHERE id = @id_conta_origem;
	--fazendo a retirada do valor da conta origem	


	UPDATE conta
	SET Saldo = Saldo + @valor
	WHERE id = @id_conta_destino;
	--incluindo o valor na conta de destino

	SELECT * FROM conta;
	--apenas visualiza antes de executar

	IF (SELECT Saldo FROM conta WHERE id = @id_conta_origem) < 0 
	BEGIN
		ROLLBACK TRAN;
		PRINT 'Transação não pode ser realizada, saldo insuficiente'
		SELECT * FROM conta;
	END
	ELSE
	BEGIN
		COMMIT TRAN;
		PRINT 'Transação realizada com sucesso!'
	END
END
GO

EXEC usp_transferencia 30, 50, 2000;
EXEC usp_transferencia 10, 50, 2000;

SELECT*FROM conta;
GO
-------------------
BEGIN TRAN
INSERT INTO conta
VALUES (50, 'Pedro', 1000);

--SAVE POINT
SAVE TRAN pedroOK 
INSERT INTO conta
VALUES (10, 'Juca', -200);
IF @@ERROR <> 0
BEGIN 
	ROLLBACK TRAN pedroOK;
	COMMIT TRAN;
	PRINT 'Voltamos para o Save Point';
END
ELSE
BEGIN
	COMMIT TRAN;
END
	SELECT * FROM conta;
GO
-----------
--TRY CATCH
--Após executar o TRY e tiver um erro dentro dele ele pula imediatamente pro CATCH, e não volta pro TRY
BEGIN TRY
	PRINT 'Olá TRY CATCH!'
	SELECT 1/0 -- ERRO PLANEJADO
	PRINT 'Não cheguei aqui'
END TRY
BEGIN CATCH
	PRINT 'Deu ERRO! '
	PRINT 'Numero: ' + CAST(ERROR_NUMBER() AS VARCHAR (10));
	PRINT 'Mensagem de ERRO: ' + ERROR_MESSAGE();
END CATCH
GO
--------------------------
BEGIN TRAN;
	BEGIN TRY
		INSERT INTO conta
		VALUES (12, 'Matheus', 1000);
		SELECT * FROM conta;
		INSERT INTO conta
		VALUES (10, 'Juca', -200);
		SELECT * FROM conta;
		COMMIT TRAN;
	END TRY
	BEGIN CATCH
		ROLLBACK TRAN;
		PRINT 'Numero: ' + CAST(ERROR_NUMBER() AS VARCHAR (10));
		PRINT 'Mensagem de ERRO: ' + ERROR_MESSAGE();
	END CATCH
	
	SELECT * FROM conta;
GO

-----------
--Inserir novo usuario no banco (não permita duplicidade de nomes).

CREATE PROCEDURE usp_cria_conta
	@id int,
	@nome varchar(50),
	@saldo MONEY
	AS
	BEGIN
		BEGIN TRAN 
		begin try
		INSERT INTO conta
		VALUES (@id, @nome, @saldo)
		SELECT * FROM conta;
		IF (Select COUNT(*) from conta where Nome = @nome)>1
		begin
			ROLLBACK TRAN	
			print 'já existe alguem com o nome: ' + @nome;
		end
		else
		begin
			commit tran
			print 'cadastro realizado com sucesso' 
		end
		end try
		begin catch
			ROLLBACK TRAN;
			PRINT 'Numero: ' + CAST(ERROR_NUMBER() AS VARCHAR (10));
			PRINT 'Mensagem de ERRO: ' + ERROR_MESSAGE();
		END CATCH
	END
	GO

EXEC usp_cria_conta 100,'Tiago', 600;
select * from conta


-- Exercicio 1
INSERT INTO DEPARTAMENTO (Dnumero, Dnome, Cpf_gerente, Data_inicio_gerente)
VALUES (10, 'Pesquisa e Desenvolvimento', NULL, NULL);
BEGIN TRANSACTION;
INSERT INTO DEPARTAMENTO (Dnumero, Dnome, Cpf_gerente, Data_inicio_gerente)
VALUES (20, 'Inovação', NULL, NULL);
ROLLBACK TRANSACTION;





-- Exercio 2
BEGIN TRANSACTION;
INSERT INTO DEPARTAMENTO (Dnumero, Dnome, Cpf_gerente, Data_inicio_gerente)
VALUES (30, 'Logística', NULL, NULL);
SAVE TRANSACTION PontoSaveLogistica;
INSERT INTO DEPARTAMENTO (Dnumero, Dnome, Cpf_gerente, Data_inicio_gerente)
VALUES (40, 'Jurídico', NULL, NULL);
ROLLBACK TRANSACTION PontoSaveLogistica;
COMMIT TRANSACTION;
