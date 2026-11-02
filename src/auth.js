const jwt = require('jsonwebtoken');
function sign(user){ return jwt.sign({id:user.id,tenantId:user.tenant_id,role:user.role,name:user.name,email:user.email},process.env.JWT_SECRET,{expiresIn:'12h'}); }
function auth(req,res,next){ const h=req.headers.authorization||''; const token=h.startsWith('Bearer ')?h.slice(7):null; if(!token) return res.status(401).json({error:'Authentication required'}); try{ req.user=jwt.verify(token,process.env.JWT_SECRET); next(); }catch{return res.status(401).json({error:'Session expired. Please sign in again.'});} }
function roles(...allowed){ return (req,res,next)=> allowed.includes(req.user.role)?next():res.status(403).json({error:'You do not have permission for this action'}); }
module.exports={sign,auth,roles};
