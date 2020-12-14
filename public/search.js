var xhr = new XMLHttpRequest();

function doSearch(){
    t = document.getElementById("searchform").value;
    xhr.onreadystatechange = checkStatus;
    xhr.open('GET','http://127.0.0.1:9998/search/'+t,true);
    xhr.responseType = 'json';
    xhr.send(null);
}

function checkStatus(){
    s="";
    if((xhr.readyState==4)&&(xhr.status==200)){
        a=xhr.response;
        l=a[0].kensu;
        if(l==0){
            s="見つかりませんでした.";
        }else{
            s=s+l+"件見つかりました.<br>";
            if(l<=100){
                s=s+"<table class=\"table table-bordered\">";
                s=s+"<tr>";
                s=s+"<th>title</th>";
                s=s+"<th>username</th>";
                s=s+"<th>更新日時</th>";
                s=s+"<th>いいね数</th>";
                s=s+"<th> </th>";
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
                    s=s+"<input type=\"submit\" value=\"Detail\">";
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