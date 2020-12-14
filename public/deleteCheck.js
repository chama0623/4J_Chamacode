function deleteCheck(){
    if(window.confirm('Really delete this article?')){
        return true;
    }else{
        window.alert('Canceled.');
        return false;
    }
}