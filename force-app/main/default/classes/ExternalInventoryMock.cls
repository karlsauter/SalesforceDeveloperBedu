@isTest
public class ExternalInventoryMock implements HttpCalloutMock {
    public HttpResponse respond(HttpRequest req) {
        HttpResponse res = new HttpResponse();
        res.setStatusCode(200);
        res.setHeader('Content-Type', 'application/json');
        res.setBody('{"statusCode":200,"body":{"Inventory":[{"name":"CL1010_Inv","ProductID":"CL1010","Quan":2906,"BlockedQuan":8},{"name":"MC1020_Inv","ProductID":"MC1020","Quan":1560,"BlockedQuan":3},{"name":"DLL1030_Inv","ProductID":"DLL1030","Quan":8290,"BlockedQuan":62}]}}');
        return res;
    }
}
