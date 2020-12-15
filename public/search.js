var xhr = new XMLHttpRequest();

function doSearch(){
    t = document.getElementById("searchform").value;
    if(t.length!=0){
        xhr.onreadystatechange = checkStatus;
        xhr.open('GET','http://'+window.location.hostname+':9998/search/'+t,true);
        xhr.responseType = 'json';
        xhr.send(null);
    }
}

function checkStatus(){
    s="";
    if((xhr.readyState==4)&&(xhr.status==200)){
        a=xhr.response;
        l=a[0].kensu;
        s="<div class=\"row mx-2\">"
        if(l==0){
            s=s+"見つかりませんでした.</div>";
        }else{
            s=s+l+"件見つかりました.</div><br>";
            if(l<=100){
                s=s+"<table class=\"table table-bordered\">";
                s=s+"<tr>";
                s=s+"<th>タイトル</th>";
                s=s+"<th>投稿者</th>";
                s=s+"<th>更新日時</th>";
                s=s+"<th>いいね数</th>";
                s=s+"<tr>";
                for(i=1;i<=l;i++){
                    s=s+"<tr>";
                    if(a[i].title.length>20){
                        s=s+"<td>"+a[i].title.substr(0,20)+"...</td>";
                    }else{
                        s=s+"<td>"+a[i].title+"</td>";
                    }
                    s=s+"<td>"+a[i].username+"</td>";
                    s=s+"<td>"+a[i].date+"</td>";
                    s=s+"<td>"+a[i].good+"</td>";
                    s=s+"<td>";
                    s=s+"<form method=\"post\" action=\"detail\">";
                    s=s+"<button type=\"submit\" class=\"btn btn-primary\">詳細</button>"
                    s=s+"<input type=\"hidden\" name=\"id\" value=\""+a[i].id+"\">";
                    s=s+"</form>";
                    s=s+"</td>";
                    s=s+"</tr>";
                }
                s=s+"</table>";
            }
        }
        document.getElementById("kekka").innerHTML=s;
    }
}