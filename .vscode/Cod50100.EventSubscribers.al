codeunit 50100 "EventSubscribers"
{
    // This even is used to catch posting of a deposit.
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Deposit-Post", 'OnAfterDepositPost', '', true, true)]
    local procedure OnAfterPostDeposit(PostedDepositHeader: Record "Posted Deposit Header");
    var
        AutoEmailLogEmail: Codeunit "SIMC AEM Log Email Meth";
        AutoEmailLog: Record "SIMC Auto Email Log";
    begin
        // We log email into auto email log.
        AutoEmailLogEmail.LogEmail(AutoEmailLog."Document Type"::Custom, 'DEPOSIT', PostedDepositHeader."No.", true);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"SIMC AEM Log Email Meth", 'OnBeforeLogSpecialDocType', '', true, true)]
    local procedure OnBeforeLogSpecialDoc(SpecialDocType: Text[100];
                                          var DocNo: code[20];
                                          var EmailTo: Text[100];
                                          var ccEmailTo: Text[100];
                                          var bccEmailTo: Text[100];
                                          var TriggerError: Boolean;
                                          var EmailTemplate: Record "SIMC AEM Email Template";
                                          var AutoEmailLog: Record "SIMC Auto Email Log");
    var
        PostedDepositHeader: Record "Posted Deposit Header";
    begin
        AutoEmailLog."Custom Document Type" := SpecialDocType;
        if SpecialDocType = 'DEPOSIT' then begin
            PostedDepositHeader.Get(DocNo);
            EmailTo := 'treasury@company.com';
            ccEmailTo := '';
            bccEmailTo := '';
            if not EmailTemplate.Get('DEPOSIT') then
                TriggerError := true
            else
                AutoEmailLog.Subject := StrSubstNo(EmailTemplate."Email Subject", PostedDepositHeader."No.", PostedDepositHeader."Total Deposit Amount");
        end;
    end;

    // Here we load all that's needed to log this document as an attachment
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"SIMC AEM Print2PDF Meth", 'OnBeforeDocumentEmailed', '', true, true)]
    local procedure OnProcessDocument(SpecialDocType: Text[20];
                                      var RecRef: RecordRef;
                                      var AutoEmailLog: Record "SIMC Auto Email Log";
                                      var EmailTemplate: Record "SIMC AEM Email Template";
                                      var DocumentName: Text;
                                      var MergeField1: Text;
                                      var MergeField2: Text);
    var
        PostedDepositHeader: Record "Posted Deposit Header";
    begin
        if SpecialDocType = 'DEPOSIT' then begin
            PostedDepositHeader.Get(AutoEmailLog."Document No.");
            PostedDepositHeader.SetRange("No.", AutoEmailLog."Document No.");
            RecRef.GETTABLE(PostedDepositHeader);
            AutoEmailLog."Custom Document Type" := SpecialDocType;
            DocumentName := StrSubstNo('Deposit %1.pdf', AutoEmailLog."Document No.", PostedDepositHeader."Total Deposit Amount");
            MergeField1 := AutoEmailLog."Document No.";
            MergeField2 := format(PostedDepositHeader."Total Deposit Amount", 0, '<Precision,2:2><Standard Format,0>');
        end;
    end;

}